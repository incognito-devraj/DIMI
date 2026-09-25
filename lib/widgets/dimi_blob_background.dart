import 'package:flutter/material.dart';

/// Soft, translucent organic blob background — Apple-inspired, premium, calm.
///
/// Four low-opacity radial gradient shapes sit on a warm cream canvas:
///   • Top-right  — warm peach/orange glow
///   • Top-left   — very faint cream highlight
///   • Bottom-center — soft warm orange
///   • Bottom-left — subtle charcoal hint (matches logo dark tone)
///
/// [opacity] lets the caller drive a fade-in. Pass [blobDrift] (in logical
/// pixels) to shift the blob layer for the slow ambient drift animation on
/// the splash screen. Both parameters are optional so the widget degrades
/// gracefully as a static background on the login screen.
class DimiBlobBackground extends StatelessWidget {
  const DimiBlobBackground({
    super.key,
    this.opacity = 1.0,
    this.blobDrift = Offset.zero,
  });

  final double opacity;

  /// Slow-drift translation applied to the blob layer only — keeps content
  /// stable while the background moves imperceptibly.
  final Offset blobDrift;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, box) => Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: blobDrift,
          child: CustomPaint(
            painter: _SoftBlobPainter(),
            size: Size(box.maxWidth, box.maxHeight),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter — four soft radial-gradient blobs on a warm cream base.
// Colors are taken directly from the DIMI logo palette but heavily faded
// (opacity 0.18–0.32) so they read as subtle depth, not decoration.
// ─────────────────────────────────────────────────────────────────────────────

class _SoftBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // ── 1. Background fill — warm cream ──────────────────────────────────
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFFAF3EB));

    // ── Helper: draw one radial gradient blob ────────────────────────────
    void blob({
      required Offset center,
      required double rx, // horizontal radius
      required double ry, // vertical radius
      required Color inner,
      required Color outer,
    }) {
      final rect = Rect.fromCenter(
        center: center,
        width: rx * 2,
        height: ry * 2,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [inner, outer],
            stops: const [0.0, 1.0],
          ).createShader(rect),
      );
    }

    // ── 2. Top-right blob — warm peach/orange ────────────────────────────
    // Clearly visible warm glow anchored to the top-right corner.
    blob(
      center: Offset(w * 0.90, h * -0.04),
      rx: w * 0.68,
      ry: h * 0.34,
      inner: const Color(0xAAF5A623), // amber, ~67 % opacity
      outer: const Color(0x00FAF3EB),
    );

    // ── 3. Bottom-center blob — soft warm orange ─────────────────────────
    blob(
      center: Offset(w * 0.50, h * 1.05),
      rx: w * 0.82,
      ry: h * 0.40,
      inner: const Color(0x88F5A000), // warm orange, ~53 % opacity
      outer: const Color(0x00FAF3EB),
    );

    // ── 4. Bottom-left dark hint — charcoal from logo ────────────────────
    blob(
      center: Offset(w * 0.04, h * 0.97),
      rx: w * 0.42,
      ry: h * 0.22,
      inner: const Color(0x3A2A2A2A), // near-black, ~23 % opacity
      outer: const Color(0x00FAF3EB),
    );

    // ── 5. Top-left highlight — faint cream shimmer ───────────────────────
    blob(
      center: Offset(w * -0.04, h * 0.06),
      rx: w * 0.48,
      ry: h * 0.24,
      inner: const Color(0x40FFFFFF), // white shimmer, ~25 % opacity
      outer: const Color(0x00FAF3EB),
    );
  }

  @override
  bool shouldRepaint(_SoftBlobPainter old) => false;
}
