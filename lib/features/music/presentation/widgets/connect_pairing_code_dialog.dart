import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connect_controller.dart';
import '../providers/music_providers.dart';

/// Mac: shows a fresh six-digit code for the next device and cancels it when
/// the dialog closes. Closes by itself once a device has paired with it.
Future<void> showConnectPairingCodeDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(connectControllerProvider.notifier);
  controller.beginPairing();
  await showDialog<void>(
    context: context,
    builder: (_) => const _ConnectPairingCodeDialog(),
  );
  controller.cancelPairing();
}

class _ConnectPairingCodeDialog extends ConsumerWidget {
  const _ConnectPairingCodeDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final code = ref.watch(
      connectControllerProvider.select((state) => state.pairingCode),
    );
    // Pairing spends the code; the dialog has done its job. Closing the
    // dialog also clears the code, while it animates out: only a dialog that
    // is still on top may pop, or the page under it would go too.
    ref.listen(connectControllerProvider.select((state) => state.pairingCode), (
      previous,
      next,
    ) {
      if (previous == null || next != null) return;
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent) Navigator.of(context).pop();
    });
    return AlertDialog(
      title: Text(strings.connectPairingCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            code == null ? '' : '${code.substring(0, 3)} ${code.substring(3)}',
            key: const ValueKey('settings-connect-pairing-code'),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          Text(strings.connectPairingCodeHint, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('settings-connect-pairing-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.close),
        ),
      ],
    );
  }
}
