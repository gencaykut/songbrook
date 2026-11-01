Songbrook for macOS: bundled open source libraries
==================================================

Songbrook plays audio on macOS with libmpv and FFmpeg. They come from the
prebuilt frameworks of media_kit_libs_macos_audio 1.1.4 (MIT), which uses the
libmpv-darwin-build v0.6.0 "audio-default" build. They are dynamic frameworks
in Songbrook.app/Contents/Frameworks.

mpv 0.36.0 (Mpv.framework)
  License: GNU LGPL version 2.1 or later (LGPL-2.1.txt). Built with
  -Dgpl=false, which leaves out mpv's GPL-only parts.
  Source: https://github.com/mpv-player/mpv/archive/refs/tags/v0.36.0.tar.gz

FFmpeg 6.0 (Avcodec, Avfilter, Avformat, Avutil, Swresample, Swscale)
  License: GNU LGPL version 3 or later (LGPL-3.0.txt, which refers to
  GPL-3.0.txt). Built with --enable-version3 and without --enable-gpl or
  --enable-nonfree; each library reports "LGPL version 3 or later".
  Source: https://ffmpeg.org/releases/ffmpeg-6.0.tar.xz

Mbed TLS 3.4.1 (Mbedcrypto, Mbedtls, Mbedx509)
  License: Apache License 2.0 (Apache-2.0.txt).
  Source: https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/v3.4.1.tar.gz

Build scripts and exact configuration:
  https://github.com/media-kit/libmpv-darwin-build/tree/v0.6.0
  https://github.com/media-kit/media-kit/tree/main/libs/macos/media_kit_libs_macos_audio

Replacing the libraries: Songbrook loads these frameworks dynamically and is
signed with the library-validation exception, so you may replace any of them
with your own build of the same library and interface version. Re-sign the
app afterwards (for example: codesign --force --deep --sign - Songbrook.app).

Copies of the source archives above are also attached to each Songbrook
release on GitHub: https://github.com/gencaykut/songbrook/releases

Songbrook itself is BSD 2-Clause licensed (Songbrook-LICENSE.txt). Other
components are listed in THIRD_PARTY_NOTICES.md in the source repository.
