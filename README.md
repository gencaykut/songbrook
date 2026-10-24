# Songbrook

![License](https://img.shields.io/badge/license-BSD--2--Clause-green)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS%20%7C%20Android-blue)

Songbrook is a YouTube Music player for macOS, iOS, and Android, built with
Flutter. It searches the YouTube Music catalog, streams and downloads songs,
and keeps a local library with playlists, favorites, and lyrics.

Songbrook is a fork of [BStream Music](https://github.com/BryamContreras/BStream-Music)
by Bryam Contreras, released under the same BSD 2-Clause license. Most of the
application, including its self-contained Dart InnerTube playback pipeline, comes
from BStream Music. The upstream README, which documents every feature in
detail, is kept at [docs/upstream-readme.md](docs/upstream-readme.md).

> The repository does not store media content. Users are responsible for
> complying with copyright law and the terms of the services they use.
> Songbrook is not affiliated with YouTube or Google.

## How Songbrook differs from BStream Music

- **Turkish interface.** Turkish joins Spanish, English, Portuguese, French,
  Korean, Chinese, and Japanese. In a Turkish interface, search and catalog
  results are requested from YouTube Music in Turkish.
- **Device language by default.** Until a language is chosen in Settings, the
  app follows the first supported language preferred by the device, falling
  back to English.
- **Correct song endings on iOS.** AVFoundation reports twice the real
  duration for YouTube's fragmented M4A audio, so songs ended minutes late
  and lock-screen transitions stalled. Streams and downloaded files are now
  clipped to their real duration. See [docs/ios-duration-fix.md](docs/ios-duration-fix.md).
- **Mobile player navigation.** The default player and the lyrics view have a
  collapse control, and the player can be pulled down to close it.
- **Volume normalization.** Songs louder than YouTube's loudness target are
  lowered to it, as on YouTube Music; quieter songs are never boosted. On by
  default, with a switch in Playback settings.
- **Search pages and playlists.** Search loads further result pages as you
  scroll, up to 200 per category, and a Playlists tab finds YouTube Music
  community playlists.
- **Playback fallbacks on Apple platforms.** The challenge-based fallback
  clients (EJS and Web PO tokens) never started on iOS and macOS; they now
  run there. When the default client fails, the audio-only visionOS01 client
  is tried before Android's client, which now serves only a 360p video stream.
- **Own identity.** Bundle ID `io.github.gencaykut.songbrook` on every
  platform, with the App Group `group.io.github.gencaykut.songbrook` for the
  iOS widget.
- **Signed macOS distribution.** A universal (Apple Silicon and Intel) DMG
  signed with Developer ID and notarized by Apple.

Windows and Linux builds still work as in BStream Music but are not tested or
distributed by this fork.

## Status

Songbrook is in development. Its numbering restarts at 1.0.0; the build
number continues above upstream's 129 so earlier test installs upgrade.

Current version: **1.0.0+130**.

| Platform | Minimum | Distribution |
| --- | --- | --- |
| macOS | 12.0, universal | Notarized DMG |
| iOS | 15.0 | AltStore / Sideloadly (AltStore PAL in the EU), planned |
| Android | 7.0 (API 24) | APK, planned; F-Droid later |

The App Store and Google Play are not targets.

Known limitations:

- Stream resolution depends on a tokenless YouTube client profile. If YouTube
  closes it, playback falls back to other profiles. Tested live on iOS and
  macOS on 2026-10-24: the tokenless fallbacks and the EJS-based
  `webEmbedded` client play, while the two Web PO token clients are currently
  rejected by YouTube's CDN. Android was not tested. See
  [docs/innertube_playback.md](docs/innertube_playback.md).
- TikTok LIVE requests are inherited from BStream Music and will be removed.
- iOS cannot play WebM, so only AAC/M4A streams are selected there.

## Build

Requirements: stable Flutter compatible with Dart `^3.12.0`; Xcode and
CocoaPods for macOS and iOS; JDK 17 and the Android SDK for Android.

```bash
flutter pub get
flutter run -d macos
flutter run -d <device-id>
```

### macOS DMG

```bash
flutter build macos --release
bash macos/package_dmg.sh "Developer ID Application: <name> (<team>)" <notary-profile>
```

The script signs the app as `Songbrook.app`, checks both architectures,
notarizes and staples it, and writes `dist/Songbrook-<version>.dmg`. Without a
`notarytool` keychain profile the DMG is signed but not notarized, and
Gatekeeper blocks it on other Macs. Create the profile once with:

```bash
xcrun notarytool store-credentials <notary-profile> --apple-id <apple-id> --team-id <team>
```

### iOS

```bash
flutter build ios --release
```

Sign `build/ios/iphoneos/Runner.app` with your own team. The Runner and the
`NowPlayingWidget` extension both need the App Group for the home-screen
widget to work.

### Android

Copy `android/key.properties.example` to `android/key.properties`, point it at
a keystore kept outside the repository, then:

```bash
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64,android-x64
```

### Icons

The app icon is drawn in `assets/icons/source/songbrook_icon.svg`; the
Android status-bar mark is `songbrook_notification.svg`. Regenerate every
platform variant on macOS with:

```bash
swift scripts/generate_app_icons.swift
```

## Quality

```bash
dart format .
flutter analyze
flutter test
```

On macOS, 47 tests fail for environmental reasons: the SQLite FFI database
tests are set up only on Windows and Linux, and two tests compare `/var` with
`/private/var`. Upstream CI runs on Ubuntu.

## Documentation

- [docs/upstream-readme.md](docs/upstream-readme.md): BStream Music's full
  feature list, architecture, and platform notes.
- [docs/innertube_playback.md](docs/innertube_playback.md): stream resolution,
  client fallback order, and PO tokens.
- [docs/ios-duration-fix.md](docs/ios-duration-fix.md): the iOS duration fixes
  (in Turkish).
- [docs/audio-routing.md](docs/audio-routing.md): audio output and casting
  (in Spanish).
- [CHANGELOG.md](CHANGELOG.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## License

BSD 2-Clause. See [LICENSE](LICENSE). Copyright for the original BStream Music
code remains with Bryam Contreras. Third-party components are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
