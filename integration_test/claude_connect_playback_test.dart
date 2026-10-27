import 'dart:async';

import 'package:bstream_music/features/music/presentation/providers/connect_controller.dart';
import 'package:bstream_music/features/music/presentation/providers/connect_playback.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/connect/connect_client.dart';
import 'package:bstream_music/services/connect/connect_discovery.dart';
import 'package:bstream_music/services/connect/connect_models.dart';
import 'package:bstream_music/services/connect/connect_store.dart';
import 'package:bstream_music/services/connect/remote_playback.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Songbrook Connect stage 3 on the Mac: the real player owns the session
/// while a second Connect device (over a real loopback WebSocket, with a
/// recording player standing in for the iPhone) pauses it, resumes it,
/// skips and seeks, takes playback over and hands it back.
///
/// flutter test integration_test/claude_connect_playback_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a remote device controls and moves the Mac playback', (
    tester,
  ) async {
    // ignore: avoid_print
    ConnectClient.logger = (message) => print('CLAUDE_LOG $message');
    final lan = _Lan();
    final macKeychain = _MemorySecureStore();
    final mac = ProviderContainer(
      overrides: [
        connectIsHostProvider.overrideWithValue(true),
        connectHostPortProvider.overrideWithValue(0),
        connectStoreProvider.overrideWithValue(ConnectStore(macKeychain)),
        connectEnabledStoreProvider.overrideWithValue(_EnabledStore(true)),
        connectBroadcasterProvider.overrideWithValue(lan),
        connectHostDiscoveryProvider.overrideWithValue(lan),
      ],
    );
    addTearDown(mac.dispose);
    final phonePlayback = _RecordingPlayback();
    final phone = ProviderContainer(
      overrides: [
        connectIsHostProvider.overrideWithValue(false),
        connectStoreProvider.overrideWithValue(
          ConnectStore(_MemorySecureStore()),
        ),
        connectEnabledStoreProvider.overrideWithValue(_EnabledStore(true)),
        connectBroadcasterProvider.overrideWithValue(lan),
        connectHostDiscoveryProvider.overrideWithValue(lan),
        connectPlaybackProvider.overrideWithValue(phonePlayback),
      ],
    );
    addTearDown(phone.dispose);
    mac.listen(connectControllerProvider, (_, _) {});
    phone.listen(connectControllerProvider, (_, _) {});

    Future<void> settle(
      String what,
      bool Function() done, {
      int seconds = 30,
    }) async {
      for (var i = 0; i < seconds * 10 && !done(); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(done(), isTrue, reason: what);
    }

    final watch = Stopwatch()..start();
    PlayerSnapshot? player() => mac.read(playerControllerProvider).value;
    int index() => mac.read(playbackQueueProvider).currentIndex;
    void log(String label) {
      final current = player();
      // ignore: avoid_print
      print(
        'CLAUDE_CONNECT ${watch.elapsedMilliseconds}ms $label '
        'index=${index()} status=${current?.status} '
        'wants=${current?.wantsToPlay} track=${current?.trackId} '
        'position=${current?.position}',
      );
    }

    final macPlayer = mac.read(playerControllerProvider.notifier);
    await mac.read(playerControllerProvider.future);
    await settle(
      'Mac host up',
      () => mac.read(connectControllerProvider).isConnected,
    );
    await settle(
      'phone sees the Mac',
      () => phone.read(connectControllerProvider).discoveredHosts.isNotEmpty,
    );
    mac.read(connectControllerProvider.notifier).beginPairing();
    await phone
        .read(connectControllerProvider.notifier)
        .pairWithHost(
          phone.read(connectControllerProvider).discoveredHosts.single,
          mac.read(connectControllerProvider).pairingCode!,
        );
    await settle(
      'paired',
      () => mac.read(connectControllerProvider).devices.length == 2,
    );
    final macId = mac.read(connectControllerProvider).connectedHostId!;
    final phoneId = mac
        .read(connectControllerProvider)
        .devices
        .firstWhere((device) => device.id != macId)
        .id;
    final remote = phone.read(connectControllerProvider.notifier);
    ConnectPlaybackSnapshot? mirrored() =>
        phone.read(connectControllerProvider).playback;

    final search = mac.read(searchControllerProvider.notifier);
    await search.submit('Tarkan');
    await settle(
      'search results',
      () => mac.read(searchControllerProvider).value?.hasSelectedPage == true,
    );
    final tracks = mac
        .read(searchControllerProvider)
        .value!
        .selectedTracks
        .take(3)
        .toList();
    expect(tracks, hasLength(3));

    unawaited(macPlayer.playRemote(tracks[0], queue: tracks));
    await settle(
      'Mac plays',
      () =>
          player()?.status == PlayerStatus.playing &&
          player()?.trackId == tracks[0].id,
    );
    log('Mac playing');
    await settle(
      'Mac owns the session',
      () => phone.read(connectControllerProvider).activeDeviceId == macId,
    );
    await settle(
      'phone mirrors the queue',
      () =>
          mirrored()?.currentTrackId == tracks[0].id &&
          mirrored()?.queue.length == 3 &&
          mirrored()!.isPlaying,
    );
    await tester.pump(const Duration(seconds: 3));

    var sent = watch.elapsedMilliseconds;
    remote.sendCommand(ConnectCommand.pause);
    await settle('paused from the phone', () => player()?.wantsToPlay == false);
    log('pause took ${watch.elapsedMilliseconds - sent}ms');
    await settle('phone sees it paused', () => mirrored()?.isPlaying == false);

    sent = watch.elapsedMilliseconds;
    remote.sendCommand(ConnectCommand.play);
    await settle(
      'resumed from the phone',
      () => player()?.status == PlayerStatus.playing,
    );
    log('play took ${watch.elapsedMilliseconds - sent}ms');

    await tester.pump(const Duration(seconds: 2));
    sent = watch.elapsedMilliseconds;
    remote.sendCommand(ConnectCommand.next);
    await settle(
      'next from the phone',
      () =>
          player()?.status == PlayerStatus.playing &&
          player()?.trackId == tracks[1].id,
    );
    log('next took ${watch.elapsedMilliseconds - sent}ms');
    expect(index(), 1);
    await settle(
      'phone sees the next song',
      () => mirrored()?.currentTrackId == tracks[1].id,
    );

    // A seek in the first moments of a song is lost in the player itself
    // (a direct seek then is too); a listener seeks a playing song.
    await tester.pump(const Duration(seconds: 2));
    remote.sendCommand(ConnectCommand.seek, {'positionMs': 60000});
    await settle(
      'seek from the phone',
      () =>
          (player()?.position ?? Duration.zero) >= const Duration(seconds: 60),
    );
    log('after seek');
    await tester.pump(const Duration(seconds: 2));

    // The phone takes playback: the Mac goes quiet once the phone is ready.
    log('before transfer');
    sent = watch.elapsedMilliseconds;
    remote.transferTo(phoneId);
    await settle('T1', () => phonePlayback.applied.isNotEmpty);
    log('prepared on phone');
    await settle('phone owns playback', () => phonePlayback.current.isPlaying);
    await settle(
      'Mac went quiet',
      () => macPlayer.localPlaybackSnapshot?.wantsToPlay == false,
    );
    log('to phone took ${watch.elapsedMilliseconds - sent}ms');
    final prepared = phonePlayback.applied.single;
    expect(prepared.isPlaying, isFalse);
    expect(prepared.currentTrackId, tracks[1].id);
    expect(prepared.positionMs, greaterThanOrEqualTo(60000));
    // The Mac's player now shows the phone's playback, and its own
    // controls go to the phone.
    await settle(
      'Mac mirrors the phone',
      () => player()?.remoteDeviceName != null && player()!.wantsToPlay,
    );
    log('Mac mirrors ${player()?.remoteDeviceName}');
    await macPlayer.pause();
    await settle(
      'Mac paused the phone',
      () => !phonePlayback.current.isPlaying,
    );
    await macPlayer.resume();
    await settle(
      'Mac resumed the phone',
      () => phonePlayback.current.isPlaying,
    );
    // ignore: avoid_print
    print(
      'CLAUDE_CONNECT phone got index=${prepared.currentIndex} '
      'position=${phonePlayback.current.positionMs}',
    );

    await tester.pump(const Duration(seconds: 2));
    // And hands it back: the Mac loads the same song, then plays from there.
    sent = watch.elapsedMilliseconds;
    remote.transferTo(macId);
    await settle(
      'Mac plays again',
      () =>
          player()?.remoteDeviceName == null &&
          player()?.status == PlayerStatus.playing &&
          player()?.trackId == tracks[1].id,
      seconds: 40,
    );
    log('back to Mac took ${watch.elapsedMilliseconds - sent}ms');
    expect(phonePlayback.current.isPlaying, isFalse);
    expect(player()?.remoteDeviceName, isNull);
    expect(index(), 1);
    expect(
      player()!.position,
      greaterThanOrEqualTo(const Duration(seconds: 60)),
    );

    await macPlayer.pause();
    await tester.pump(const Duration(seconds: 1));
  });
}

class _MemorySecureStore implements ConnectSecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _EnabledStore implements ConnectEnabledStore {
  _EnabledStore(this.enabled);

  bool enabled;

  @override
  Future<bool> read() async => enabled;

  @override
  Future<void> write(bool value) async => enabled = value;
}

/// Bonjour stand-in: whatever the Mac advertises, the phone finds.
class _Lan implements ConnectBroadcaster, ConnectHostDiscovery {
  final _hosts = StreamController<List<ConnectDiscoveredHost>>.broadcast();
  ConnectDiscoveredHost? _advertised;

  @override
  Stream<List<ConnectDiscoveredHost>> get hosts => _hosts.stream;

  @override
  Future<void> start({String? hostId, String? name, int? port}) async {
    if (hostId != null) {
      _advertised = ConnectDiscoveredHost(
        hostId: hostId,
        name: name!,
        addresses: const ['127.0.0.1'],
        port: port!,
      );
      _hosts.add([_advertised!]);
      return;
    }
    final host = _advertised;
    if (host != null) scheduleMicrotask(() => _hosts.add([host]));
  }

  @override
  Future<void> stop() async {}
}

/// The iPhone's player: records what Connect asks of it.
class _RecordingPlayback implements ConnectPlayback {
  final _changes = StreamController<ConnectPlaybackChange>.broadcast();
  final applied = <ConnectPlaybackSnapshot>[];
  ConnectPlaybackSnapshot current = ConnectPlaybackSnapshot.fromJson(const {});

  void _set({bool? isPlaying, int? positionMs}) {
    current = current.copyWith(
      isPlaying: isPlaying,
      positionMs: positionMs,
      updatedAt: DateTime.now().toUtc(),
    );
    _changes.add(
      ConnectPlaybackChange(
        started: isPlaying == true,
        stopped: isPlaying == false,
      ),
    );
  }

  @override
  Set<String> get supportedCommands => kConnectPlayerCommands;

  @override
  Stream<ConnectPlaybackChange> get changes => _changes.stream;

  @override
  ConnectPlaybackSnapshot snapshot() => current.compensated(DateTime.now());

  @override
  Future<void> apply(ConnectPlaybackSnapshot snapshot) async {
    applied.add(snapshot);
    current = snapshot;
  }

  @override
  Future<void> handleCommand(
    String command,
    Map<String, dynamic> arguments,
  ) async {
    switch (command) {
      case ConnectCommand.pause:
        _set(isPlaying: false);
      case ConnectCommand.play:
        _set(isPlaying: true);
      case ConnectCommand.seek:
        _set(positionMs: arguments['positionMs'] as int);
    }
  }

  @override
  Future<void> pauseForTransfer() async => _set(isPlaying: false);

  ConnectRemotePlayback? mirrored;

  @override
  void mirror(ConnectRemotePlayback? remote, ConnectRemoteControl? control) =>
      mirrored = remote;
}
