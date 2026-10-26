# Third-party notices

## Google Cast sender SDKs

BStream Music integrates the official Google Cast sender SDKs for Android
(`com.google.android.gms:play-services-cast-framework` 22.3.1) and iOS
(`google-cast-sdk-no-bluetooth` 4.8.0), using the default media receiver.
These proprietary SDKs are distributed under Google's applicable SDK terms,
not the license of this application's original casting code.

Documentation: <https://developers.google.com/cast/docs/overview>

Terms: <https://developers.google.com/cast/docs/terms>

AndroidX MediaRouter is licensed under Apache-2.0:
<https://android.googlesource.com/platform/frameworks/support/+/androidx-main/LICENSE.txt>

## xml 6.6.1

BStream Music uses the Dart `xml` package (MIT license) for bounded UPnP device
descriptions and SOAP messages. Source and license:
<https://github.com/renggli/dart-xml/blob/v6.6.1/LICENSE>

## Kyant AndroidLiquidGlass 2.0.0

BStream Music's rounded-rectangle refraction shader adapts the optical model
from Kyant AndroidLiquidGlass, also used by Echo Music.

Source: <https://github.com/Kyant0/AndroidLiquidGlass/tree/2.0.0>

Licensed under the Apache License, Version 2.0. A copy of the license is
included at `third_party/kyant_android_liquid_glass/LICENSE`.

## csv 8.0.0

BStream Music uses the `csv` Dart package to parse and encode interoperable
CSV library files.

Source: <https://pub.dev/packages/csv>

The MIT License (MIT)

Copyright (c) 2014 Christian Loitsch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Ariami Connect

Songbrook Connect's wire models, hub, client and their tests
(`lib/services/connect/`, `test/services/connect/`) are adapted from Ariami
Connect, commit `9b8d27e`. Names were changed and Ariami's library-server
notifications removed; the protocol and its rules are Ariami's.

Source: <https://github.com/picccassso/Ariami>

MIT License

Copyright (c) 2026 Alex (aka Picasso)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## web_socket_channel

Songbrook Connect uses the Dart `web_socket_channel` package (BSD-3-Clause)
for its WebSocket transport. Source and license:
<https://github.com/dart-lang/http/tree/master/pkgs/web_socket_channel>

## SponsorBlock data

Songbrook skips the non-music parts of music videos (the `music_offtopic`
category) using segments from SponsorBlock, a community database by Ajay
Ramachandran and contributors. The data is licensed under the Creative
Commons Attribution-NonCommercial-ShareAlike 4.0 International License
(CC BY-NC-SA 4.0). Songbrook requests it by the first four characters of the
video's SHA-256 hash and does not redistribute it.

Source: <https://sponsor.ajay.app>

License: <https://creativecommons.org/licenses/by-nc-sa/4.0/>

## EJS 0.8.0

BStream Music directly consumes Base64-encoded copies of the checksum-pinned
EJS release modules to solve YouTube player challenges inside its isolated
headless JavaScript runtime. The decoded bytes are verified against the
upstream SHA-256 values before execution. A download of those same pinned
release artifacts is kept only as a checksum-verified recovery fallback when a
bundled asset is missing or corrupt.

EJS is a separate upstream project hosted under the yt-dlp GitHub organization.
Its inclusion does not make BStream dependent on the yt-dlp program or Python
package: BStream neither bundles nor invokes the yt-dlp executable.

Source: <https://github.com/yt-dlp/ejs>

The Unlicense

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.

In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>.

### meriyah 6.1.4 (bundled by EJS)

Source: <https://github.com/meriyah/meriyah>

ISC License

Copyright (c) 2019 and later, KFlash and others.

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.

### astring 1.9.0 (bundled by EJS)

Source: <https://github.com/davidbonnet/astring>

The MIT License (MIT)

Copyright (c) 2015, David Bonnet <david@bonnet.cc>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
