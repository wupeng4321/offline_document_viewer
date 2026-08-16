import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:offline_document_viewer/offline_document_viewer.dart';

import '../design/app_theme.dart';
import '../design/component.dart';

/// A format stamp.
///
/// The package exposes [DocumentFormat.family], which is all an application
/// needs to build its own visual language — colour choices stay here rather
/// than being dictated by the package.
class FormatBadge extends StatelessWidget {
  const FormatBadge({
    required this.format,
    this.size = Dims.stamp,
    this.tilt = 0,
    super.key,
  });

  final DocumentFormat format;
  final double size;

  /// Rotation in degrees; a slight tilt reads as "stamped".
  final double tilt;

  /// Office's own colour language — users already recognise these.
  static Color colorOf(DocumentFormat format) => switch (format.family) {
        FormatFamily.pdf => const Color(0xFFC0392B),
        FormatFamily.word => const Color(0xFF2A5699),
        FormatFamily.excel => const Color(0xFF1E6B43),
        FormatFamily.powerPoint => const Color(0xFFC0451F),
        FormatFamily.plain => const Color(0xFF5C5648),
      };

  /// Fidelity, phrased for people.
  static String fidelityLabel(FidelityLevel level) => switch (level) {
        FidelityLevel.full => 'FULL FIDELITY',
        FidelityLevel.high => 'HIGH FIDELITY',
        FidelityLevel.partial => 'PARTIAL FORMATTING',
        FidelityLevel.textOnly => 'TEXT ONLY',
      };

  @override
  Widget build(BuildContext context) {
    final Color color = colorOf(format);
    final String label = format.extensions.first.toUpperCase();

    return Transform.rotate(
      angle: tilt * math.pi / 180,
      child: Semantics(
        label: label,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: context.colors.surface.withValues(alpha: 0.28),
              width: 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xxs),
              child: Text(
                label,
                style: context.texts.labelMedium?.copyWith(
                  color: context.colors.surface,
                  fontSize: size * 0.26,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
