import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/connect/connect_models.dart';
import '../providers/connect_controller.dart';
import '../providers/music_providers.dart';

/// Songbrook Connect's device button: shown while this device is connected
/// to other Songbrook devices; it opens the device picker. Highlighted while
/// another device is playing.
class ConnectDevicesButton extends ConsumerWidget {
  const ConnectDevicesButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectControllerProvider);
    if (!state.enabled || !state.isConnected || state.devices.length < 2) {
      return const SizedBox.shrink();
    }
    final strings = ref.watch(appStringsProvider);
    final elsewhere =
        state.activeDeviceId != null &&
        state.activeDeviceId != state.selfDeviceId;
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      key: const ValueKey('connect-devices-button'),
      tooltip: strings.connectDevices,
      style: IconButton.styleFrom(
        foregroundColor: elsewhere ? colors.primary : color,
        backgroundColor: elsewhere
            ? colors.primary.withValues(alpha: 0.16)
            : Colors.transparent,
      ),
      icon: const Icon(Icons.devices_rounded),
      onPressed: () => showConnectDevicePicker(context),
    );
  }
}

Future<void> showConnectDevicePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => const _ConnectDevicePicker(),
  );
}

class _ConnectDevicePicker extends ConsumerWidget {
  const _ConnectDevicePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final controller = ref.read(connectControllerProvider.notifier);
    final selfId = state.selfDeviceId;
    // Playback can move once some device has played in this session.
    final hasSession = state.activeDeviceId != null;
    final devices = [...state.devices]
      // This device first, then the others by name.
      ..sort((a, b) {
        if (a.id == selfId) return -1;
        if (b.id == selfId) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return SafeArea(
      top: false,
      child: Column(
        key: const ValueKey('connect-device-picker'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              strings.connectDevices,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final device in devices)
            _DeviceTile(
              device: device,
              isSelf: device.id == selfId,
              isActive: device.id == state.activeDeviceId,
              enabled: hasSession && device.canPlay,
              strings: strings,
              onTap: () {
                Navigator.of(context).pop();
                if (device.id != state.activeDeviceId) {
                  controller.transferTo(device.id);
                }
              },
            ),
          if (!hasSession)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                strings.connectNothingToMove,
                key: const ValueKey('connect-nothing-to-move'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.isSelf,
    required this.isActive,
    required this.enabled,
    required this.strings,
    required this.onTap,
  });

  final ConnectDevice device;
  final bool isSelf;
  final bool isActive;
  final bool enabled;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = device.type == 'desktop'
        ? Icons.laptop_mac_rounded
        : Icons.smartphone_rounded;
    return ListTile(
      key: ValueKey('connect-device-${device.id}'),
      enabled: enabled || isActive,
      leading: Icon(icon, color: isActive ? colors.primary : null),
      title: Text(
        isSelf ? '${strings.connectThisDevice} · ${device.name}' : device.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isActive
            ? TextStyle(color: colors.primary, fontWeight: FontWeight.w700)
            : null,
      ),
      subtitle: isActive
          ? Text(strings.connectPlaying)
          : enabled
          ? Text(strings.connectTapToPlayHere)
          : null,
      trailing: isActive
          ? Icon(Icons.volume_up_rounded, color: colors.primary)
          : null,
      onTap: isActive ? () => Navigator.of(context).pop() : onTap,
    );
  }
}
