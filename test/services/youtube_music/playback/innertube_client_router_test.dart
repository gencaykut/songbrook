import 'package:bstream_music/services/youtube_music/playback/innertube_client_profile.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_client_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the benchmark primary ahead of faster fallbacks', () {
    final router = InnerTubeClientRouter();
    router
      ..recordSuccess('visionOS', const Duration(milliseconds: 900))
      ..recordSuccess('androidSdkless', const Duration(milliseconds: 250));

    expect(
      router.candidates().take(2).map((profile) => profile.key),
      orderedEquals(<String>['visionOS', 'androidSdkless']),
    );
  });

  test('tries audio-only fallbacks before Android\'s muxed stream', () {
    final router = InnerTubeClientRouter();
    expect(
      router
          .candidates(skipPrimary: true)
          .take(2)
          .map((profile) => profile.key),
      orderedEquals(<String>['visionOS01', 'androidSdkless']),
    );

    // visionOS01 cannot serve one video, so Android serves its muxed stream,
    // faster than visionOS01 serves the rest.
    router
      ..recordSuccess('visionOS01', const Duration(milliseconds: 900))
      ..recordSuccess(
        'androidSdkless',
        const Duration(milliseconds: 300),
        muxed: true,
      );
    expect(router.healthFor('androidSdkless').lastSuccessWasMuxed, isTrue);
    expect(
      router
          .candidates(skipPrimary: true)
          .take(2)
          .map((profile) => profile.key),
      orderedEquals(<String>['visionOS01', 'androidSdkless']),
      reason: 'A muxed stream never outranks an audio-only one on latency.',
    );

    expect(
      router.candidates(skipPrimary: true).skip(2).first.key,
      'webEmbedded',
      reason: 'Unmeasured later clients keep their place behind Android.',
    );

    router.recordSuccess('androidSdkless', const Duration(milliseconds: 300));
    expect(
      router.candidates(skipPrimary: true).first.key,
      'androidSdkless',
      reason: 'Once Android serves audio alone again, latency decides.',
    );
  });

  test('a muxed success does not jump an earlier unmeasured client', () {
    // visionOS01 failed its first video, so only Android has a latency.
    final router = InnerTubeClientRouter()
      ..recordFailure('visionOS01', InnerTubeClientFailureKind.unavailable)
      ..recordSuccess(
        'androidSdkless',
        const Duration(milliseconds: 300),
        muxed: true,
      );

    expect(
      router
          .candidates(skipPrimary: true)
          .take(3)
          .map((profile) => profile.key),
      orderedEquals(<String>['visionOS01', 'androidSdkless', 'webEmbedded']),
    );
  });

  test('moves a repeatedly failing primary behind healthy clients', () {
    var now = DateTime.utc(2026, 8, 31);
    final router = InnerTubeClientRouter(clock: () => now);
    router
      ..recordFailure('visionOS', InnerTubeClientFailureKind.rejected)
      ..recordFailure('visionOS', InnerTubeClientFailureKind.rejected);

    expect(router.candidates().last.key, 'visionOS');
    expect(router.healthFor('visionOS').isCoolingDownAt(now), isTrue);

    now = now.add(const Duration(minutes: 3));
    expect(router.candidates().first.key, 'visionOS');
  });

  test('filters profiles whose challenge runtime is unavailable', () {
    final router = InnerTubeClientRouter();

    expect(
      router.candidates(supportsJavaScript: false, supportsWebPo: false),
      <InnerTubeClientProfile>[
        InnerTubeClientRegistry.visionOS,
        InnerTubeClientRegistry.visionOS01,
        InnerTubeClientRegistry.androidSdkless,
      ],
    );
  });

  test('fallback mode skips the default profile', () {
    final router = InnerTubeClientRouter();

    expect(
      router.candidates(skipPrimary: true).map((profile) => profile.key),
      isNot(contains('visionOS')),
    );
  });

  test('can exclude the exact profile that produced a rejected stream', () {
    final router = InnerTubeClientRouter();

    expect(
      router
          .candidates(
            skipPrimary: true,
            excludedProfileKeys: const <String>{'androidSdkless'},
          )
          .map((profile) => profile.key),
      allOf(isNot(contains('visionOS')), isNot(contains('androidSdkless'))),
    );
  });
}
