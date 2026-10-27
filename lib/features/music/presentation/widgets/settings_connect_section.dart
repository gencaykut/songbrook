part of 'settings_panel.dart';

/// Settings → Songbrook Connect: the switch, and on the Mac the pairing code
/// and paired devices, or on a phone the Macs on the network.
class _ConnectSettings extends ConsumerWidget {
  const _ConnectSettings({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectControllerProvider);
    final controller = ref.read(connectControllerProvider.notifier);
    final connectedIds = state.devices.map((device) => device.id).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlaybackSwitchSettings(
          key: const ValueKey('settings-inline-connect'),
          switchKey: const ValueKey('settings-connect-switch'),
          enabled: state.enabled,
          icon: Icons.devices_rounded,
          title: kConnectProductName,
          summary: state.isHost
              ? strings.connectHostSummary
              : strings.connectClientSummary,
          onEnabledChanged: state.loaded ? controller.setEnabled : (_) {},
        ),
        if (state.enabled) ...[
          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              state.errorMessage == ConnectState.pairingRemovedError
                  ? strings.connectPairingRemoved
                  : strings.connectFailed,
              style: appListCardSubtitleStyle(context),
            ),
            // The cause, for reporting a problem; it is not translated.
            if (state.errorMessage != ConnectState.pairingRemovedError)
              SelectableText(
                state.errorMessage!,
                key: const ValueKey('settings-connect-error-detail'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
          if (state.isHost) ...[
            const SizedBox(height: appCardGap),
            _SettingsEntryCard(
              key: const ValueKey('settings-connect-add-device'),
              icon: Icons.add_link_rounded,
              title: strings.connectAddDevice,
              subtitle: strings.connectAddDeviceSummary,
              onTap: () => _showPairingCode(context, ref),
            ),
            for (final device in state.pairedDevices) ...[
              const SizedBox(height: appCardGap),
              _SettingsEntryCard(
                key: ValueKey('settings-connect-device-${device.id}'),
                icon: device.type == 'desktop'
                    ? Icons.laptop_mac_rounded
                    : Icons.smartphone_rounded,
                title: device.name,
                subtitle: connectedIds.contains(device.id)
                    ? strings.connectConnected
                    : strings.connectNotConnected,
                onTap: null,
                trailing: IconButton(
                  tooltip: strings.connectRemoveDevice,
                  icon: const Icon(Icons.link_off_rounded),
                  onPressed: () => _confirmRemove(context, ref, device),
                ),
              ),
            ],
          ] else
            ..._clientRows(context, ref, state),
        ],
      ],
    );
  }

  List<Widget> _clientRows(
    BuildContext context,
    WidgetRef ref,
    ConnectState state,
  ) {
    final controller = ref.read(connectControllerProvider.notifier);
    final discovered = {
      for (final host in state.discoveredHosts) host.hostId: host,
    };
    final knownIds = state.knownHosts.map((host) => host.hostId).toSet();
    final rows = <Widget>[];
    for (final known in state.knownHosts) {
      final connected =
          state.connectedHostId == known.hostId && state.isConnected;
      rows.addAll([
        const SizedBox(height: appCardGap),
        _SettingsEntryCard(
          key: ValueKey('settings-connect-host-${known.hostId}'),
          icon: Icons.laptop_mac_rounded,
          title: known.hostName,
          subtitle: connected
              ? strings.connectConnected
              : discovered.containsKey(known.hostId)
              ? strings.connectNotConnected
              : strings.connectNotFound,
          onTap: null,
          trailing: TextButton(
            onPressed: () => controller.forgetHost(known.hostId),
            child: Text(strings.connectForget),
          ),
        ),
      ]);
    }
    for (final host in state.discoveredHosts) {
      if (knownIds.contains(host.hostId)) continue;
      rows.addAll([
        const SizedBox(height: appCardGap),
        _SettingsEntryCard(
          key: ValueKey('settings-connect-discovered-${host.hostId}'),
          icon: Icons.laptop_mac_rounded,
          title: host.name,
          subtitle: strings.connectTapToPair,
          onTap: () => _pair(context, ref, host),
        ),
      ]);
    }
    if (rows.isEmpty) {
      rows.addAll([
        const SizedBox(height: appCardGap),
        _SettingsEntryCard(
          key: const ValueKey('settings-connect-searching'),
          icon: Icons.wifi_find_rounded,
          title: strings.connectSearching,
          subtitle: strings.connectSearchingSummary,
          onTap: null,
        ),
      ]);
    }
    return rows;
  }

  Future<void> _showPairingCode(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(connectControllerProvider.notifier);
    controller.beginPairing();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final code = ref.watch(
            connectControllerProvider.select((state) => state.pairingCode),
          );
          // Pairing spends the code; the dialog has done its job.
          if (code == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            });
          }
          return AlertDialog(
            title: Text(strings.connectPairingCodeTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code == null
                      ? ''
                      : '${code.substring(0, 3)} ${code.substring(3)}',
                  key: const ValueKey('settings-connect-pairing-code'),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.connectPairingCodeHint,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(strings.close),
              ),
            ],
          );
        },
      ),
    );
    controller.cancelPairing();
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    ConnectPairedDevice device,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(device.name),
        content: Text(strings.connectRemoveDeviceSummary),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.connectRemoveDevice),
          ),
        ],
      ),
    );
    if (remove == true) {
      await ref
          .read(connectControllerProvider.notifier)
          .revokeDevice(device.id);
    }
  }

  Future<void> _pair(
    BuildContext context,
    WidgetRef ref,
    ConnectDiscoveredHost host,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _ConnectPairDialog(
        host: host,
        strings: strings,
        onPair: (code) => ref
            .read(connectControllerProvider.notifier)
            .pairWithHost(host, code),
      ),
    );
  }
}

class _ConnectPairDialog extends StatefulWidget {
  const _ConnectPairDialog({
    required this.host,
    required this.strings,
    required this.onPair,
  });

  final ConnectDiscoveredHost host;
  final AppStrings strings;
  final Future<void> Function(String code) onPair;

  @override
  State<_ConnectPairDialog> createState() => _ConnectPairDialogState();
}

class _ConnectPairDialogState extends State<_ConnectPairDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onPair(code);
      if (mounted) Navigator.of(context).pop();
    } on ConnectPairingException catch (error) {
      if (!mounted) return;
      final strings = widget.strings;
      setState(() {
        _busy = false;
        _error = switch (error.code) {
          'WRONG_CODE' => strings.connectWrongCode,
          'CODE_EXPIRED' => strings.connectCodeExpired,
          'TOO_MANY_ATTEMPTS' => strings.connectTooManyAttempts,
          'NO_CODE' => strings.connectNoCode,
          _ => strings.connectUnreachable,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = widget.strings.connectUnreachable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AlertDialog(
      title: Text(widget.host.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.connectEnterCode),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('settings-connect-code-field'),
            controller: _controller,
            autofocus: true,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              letterSpacing: 6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: '000000',
              helperText: strings.connectEnterCodeHint,
              helperMaxLines: 3,
              errorText: _error,
              errorMaxLines: 3,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          key: const ValueKey('settings-connect-pair-button'),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(strings.connectPair),
        ),
      ],
    );
  }
}
