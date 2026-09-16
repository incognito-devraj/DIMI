import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Positions a modal as a fixed-size card and translates it only when the
/// keyboard intersects its lower edge.
class DimiFixedDialog extends StatefulWidget {
  const DimiFixedDialog({
    super.key,
    required this.height,
    required this.child,
    this.maxWidth = 500,
  });

  final double height;
  final Widget child;
  final double maxWidth;

  @override
  State<DimiFixedDialog> createState() => _DimiFixedDialogState();
}

class _DimiFixedDialogState extends State<DimiFixedDialog> {
  double? _restingHeight;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final restingHeight = _restingHeight ??= MediaQuery.sizeOf(context).height;
    const defaultTopFraction = 0.19;
    final defaultTop = restingHeight * defaultTopFraction;
    final keyboardTop = restingHeight - media.viewInsets.bottom;
    final dialogBottom = defaultTop + widget.height + 24;
    final overlap = math.max(0.0, dialogBottom - keyboardTop);
    final top = math.max(media.padding.top + 8, defaultTop - overlap);

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedPadding(
        padding: EdgeInsets.only(top: top),
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Material(
          type: MaterialType.transparency,
          child: MediaQuery(
            data: media.copyWith(
              size: Size(media.size.width, restingHeight),
              viewInsets: EdgeInsets.zero,
            ),
            child: SizedBox(
              width: math.min(media.size.width - 44, widget.maxWidth),
              height: widget.height,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
