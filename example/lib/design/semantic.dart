import 'dart:ui' show Brightness, Color;

import 'package:flutter/foundation.dart' show immutable;

import 'primitives.dart';

/// Anlam taşıyan renk takma adları.
///
/// Widget'lar yalnızca buraya ve `component.dart`'a dokunur; ham palete
/// (`Prim`) doğrudan erişim temayı tek noktadan değiştirmeyi bozar.
@immutable
class AppColors {
  const AppColors({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceInverse,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.onSurfaceFaint,
    required this.onSurfaceInverse,
    required this.hairline,
    required this.hairlineStrong,
    required this.accent,
    required this.onAccent,
    required this.accentMuted,
    required this.focus,
    required this.danger,
    required this.onDanger,
    required this.dangerMuted,
    required this.warning,
    required this.warningMuted,
    required this.success,
    required this.scrim,
    required this.documentSurface,
    required this.grain,
    required this.brightness,
  });

  /// Açık tema — krem kâğıt, mürekkep yazı.
  factory AppColors.light() => const AppColors(
        surface: Prim.paper0,
        surfaceRaised: Prim.paper1,
        surfaceSunken: Prim.paper2,
        surfaceInverse: Prim.ink0,
        onSurface: Prim.ink0,
        onSurfaceMuted: Prim.ink5,
        onSurfaceFaint: Prim.ink6,
        onSurfaceInverse: Prim.paper0,
        hairline: Prim.ink8,
        hairlineStrong: Prim.ink7,
        accent: Prim.stamp,
        onAccent: Prim.paper1,
        accentMuted: Prim.stampWash,
        focus: Prim.stamp,
        danger: Prim.stamp,
        onDanger: Prim.paper1,
        dangerMuted: Prim.stampWash,
        warning: Prim.amber,
        warningMuted: Prim.amberWash,
        success: Prim.green,
        scrim: Color(0x59120F0B),
        documentSurface: Prim.white,
        grain: Color(0x0D0C0B0A),
        brightness: Brightness.light,
      );

  /// Koyu tema — mürekkep zemin, kâğıt yazı.
  ///
  /// `documentSurface` bilerek beyaz kalıyor: belge sadakati kabuk temasından
  /// bağımsız (bkz. `docs/plans/06_goruntuleyici_ui.md`).
  factory AppColors.dark() => const AppColors(
        surface: Prim.ink0,
        surfaceRaised: Prim.ink1,
        surfaceSunken: Prim.ink0,
        surfaceInverse: Prim.paper0,
        onSurface: Prim.paper0,
        onSurfaceMuted: Prim.ink7,
        onSurfaceFaint: Prim.ink6,
        onSurfaceInverse: Prim.ink0,
        hairline: Prim.ink3,
        hairlineStrong: Prim.ink4,
        accent: Prim.stampBright,
        onAccent: Prim.ink0,
        accentMuted: Prim.stampMuted,
        focus: Prim.stampBright,
        danger: Prim.stampBright,
        onDanger: Prim.ink0,
        dangerMuted: Prim.stampMuted,
        warning: Prim.amber,
        warningMuted: Prim.ink2,
        success: Prim.green,
        scrim: Color(0xA60C0B0A),
        documentSurface: Prim.white,
        grain: Color(0x14F6F2E9),
        brightness: Brightness.dark,
      );

  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color surfaceInverse;

  final Color onSurface;
  final Color onSurfaceMuted;
  final Color onSurfaceFaint;
  final Color onSurfaceInverse;

  final Color hairline;
  final Color hairlineStrong;

  final Color accent;
  final Color onAccent;
  final Color accentMuted;
  final Color focus;

  final Color danger;
  final Color onDanger;
  final Color dangerMuted;
  final Color warning;
  final Color warningMuted;
  final Color success;

  final Color scrim;

  /// Belgenin çizildiği yüzey. Fidelity için her iki temada da beyaz.
  final Color documentSurface;

  /// Kâğıt dokusu için serpme rengi — zemine göre koyu ya da açık.
  final Color grain;

  final Brightness brightness;
}
