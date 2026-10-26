import 'dart:async';

import 'package:flutter/material.dart';

/// Draws a thin progress ring around a play/pause control while playback is
/// wanted but no audio is coming out yet.
///
/// The ring appears only after [delay], so the short buffering events of a
/// seek or a fast start do not make it flash.
class PlaybackWaitIndicator extends StatefulWidget {
  const PlaybackWaitIndicator({
    super.key,
    required this.waiting,
    required this.child,
    this.color,
    this.strokeWidth = 2,
    this.delay = const Duration(milliseconds: 250),
  });

  final bool waiting;
  final Widget child;

  /// Defaults to the icon color of the surrounding theme.
  final Color? color;
  final double strokeWidth;
  final Duration delay;

  @override
  State<PlaybackWaitIndicator> createState() => _PlaybackWaitIndicatorState();
}

class _PlaybackWaitIndicatorState extends State<PlaybackWaitIndicator> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(PlaybackWaitIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waiting != widget.waiting) {
      _sync();
    }
  }

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (!widget.waiting) {
      _visible = false;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? IconTheme.of(context).color;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        if (_visible)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.all(widget.strokeWidth / 2),
                child: CircularProgressIndicator(
                  key: const ValueKey('playback-wait-indicator'),
                  // A static arc still says "waiting" without motion.
                  value: reduceMotion ? 0.25 : null,
                  strokeWidth: widget.strokeWidth,
                  strokeCap: StrokeCap.round,
                  color: color?.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
