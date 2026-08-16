import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'app_theme.dart';

/// Kâğıt dokusu zemini.
///
/// Düz bir renk ekranı "dijital" gösteriyor; ince bir tanecik ve yumuşak bir
/// aydınlanma yüzeye fiziksellik veriyor. Doku tek seferde çiziliyor
/// (`isComplex` + `willChange: false`), kaydırma maliyeti yok.
class PaperBackdrop extends StatelessWidget {
  const PaperBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: context.colors.surface),
      child: CustomPaint(
        painter: _GrainPainter(
          grain: context.colors.grain,
          glow: context.colors.surfaceRaised,
        ),
        isComplex: true,
        willChange: false,
        child: child,
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.grain, required this.glow});

  final Color grain;
  final Color glow;

  /// Sabit tohum: doku her karede değişirse titreşim olur, kâğıt olmaz.
  static const int _seed = 20260811;
  static const int _dots = 1400;

  @override
  void paint(Canvas canvas, Size size) {
    // Sol üstten gelen yumuşak aydınlanma — sayfanın bir ışık kaynağı var.
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, -0.9),
          radius: 1.4,
          colors: <Color>[glow, glow.withValues(alpha: 0)],
        ).createShader(rect),
    );

    final math.Random random = math.Random(_seed);
    final Paint dot = Paint()..color = grain;
    for (int i = 0; i < _dots; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        random.nextDouble() * 0.9 + 0.2,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.grain != grain || oldDelegate.glow != glow;
}
