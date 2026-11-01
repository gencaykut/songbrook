#!/usr/bin/env bash
# Packages a release build as a Developer ID signed, notarized Songbrook DMG.
#
# Usage: macos/package_dmg.sh <signing-identity> [notary-profile]
#
# Build first with `flutter build macos --release`. Without a notarytool
# keychain profile the DMG is signed but not notarized. Create the profile once:
#   xcrun notarytool store-credentials <profile> --apple-id <id> --team-id <team>
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <signing-identity> [notary-profile]" >&2
  exit 64
fi

signing_identity="$1"
notary_profile="${2:-}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$script_dir/.." && pwd)"
built_app="$root/build/macos/Build/Products/Release/bstream_music.app"
dist="$root/dist"
staging="$dist/dmg-staging"
app="$staging/Songbrook.app"

if [[ ! -d "$built_app" ]]; then
  echo "Missing release build: $built_app" >&2
  exit 66
fi

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "$built_app/Contents/Info.plist")"
dmg="$dist/Songbrook-$version.dmg"

notarize() {
  [[ -n "$notary_profile" ]] || return 0
  /usr/bin/xcrun notarytool submit "$1" \
    --keychain-profile "$notary_profile" \
    --wait
}

rm -rf "$staging" "$dmg"
mkdir -p "$staging"
# The product keeps upstream's bstream_music name so CI and scripts stay
# unchanged; renaming the bundle directory does not affect its signature.
/usr/bin/ditto "$built_app" "$app"

# The LGPL libmpv/FFmpeg frameworks must ship with their notices; keep them
# inside the app (before signing) and next to it in the DMG.
copy_licenses() {
  mkdir -p "$1"
  cp "$script_dir"/licenses/*.txt "$1/"
  cp "$root/LICENSE" "$1/Songbrook-LICENSE.txt"
}
copy_licenses "$app/Contents/Resources/Licenses"
copy_licenses "$staging/Licenses"

bash "$script_dir/sign_release_bundle.sh" "$app" "$signing_identity"
for arch in $(/usr/bin/lipo -archs "$app/Contents/MacOS/bstream_music"); do
  bash "$script_dir/verify_release_bundle.sh" "$app" "$arch" "$version"
done

if [[ -n "$notary_profile" ]]; then
  zip="$dist/Songbrook-$version-notarize.zip"
  /usr/bin/ditto -c -k --keepParent "$app" "$zip"
  notarize "$zip"
  rm -f "$zip"
  # Stapling the app lets it pass Gatekeeper after leaving the DMG offline.
  /usr/bin/xcrun stapler staple "$app"
fi

ln -s /Applications "$staging/Applications"
/usr/bin/hdiutil create \
  -volname "Songbrook" \
  -srcfolder "$staging" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$dmg"
/usr/bin/codesign --force --timestamp --sign "$signing_identity" "$dmg"

if [[ -n "$notary_profile" ]]; then
  notarize "$dmg"
  /usr/bin/xcrun stapler staple "$dmg"
  /usr/sbin/spctl --assess --type open --context context:primary-signature \
    --verbose=4 "$dmg"
  /usr/sbin/spctl --assess --type execute --verbose=4 "$app"
fi

rm -rf "$staging"
echo "$dmg"
