import 'package:flutter/material.dart';

import 'component.dart';
import 'primitives.dart';
import 'semantic.dart';

/// Anlamsal renkleri `Theme` üzerinden taşıyan uzantı.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension(this.colors);

  final AppColors colors;

  @override
  AppColorsExtension copyWith({AppColors? colors}) =>
      AppColorsExtension(colors ?? this.colors);

  /// İki ayrık şema arasında ara kare üretmek yerine hedefe geçiyoruz;
  /// yarı yolda okunmaz kontrast oluşmuyor.
  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColorsExtension>()!.colors;

  TextTheme get texts => Theme.of(this).textTheme;
}

/// Uygulama teması.
///
/// **Üç sesli tipografi** — arşiv estetiğinin taşıyıcısı:
///
/// - `Caladea` (serif) → başlıklar ve belge adları. Karakterli, editöryel.
/// - `Carlito` (sans) → gövde metni. Nötr, okunur, geri planda.
/// - `EvrakMono` (daktilo) → künye, sayı, etiket. Kataloğun sesi.
///
/// Üçü de zaten belge motorları için gömülü olan metrik-uyumlu fontlar;
/// arayüz için ayrıca font paketlemiyoruz (ADR-009).
abstract final class AppTheme {
  static const String displayFamily = 'Caladea';
  static const String bodyFamily = 'Carlito';
  static const String monoFamily = 'EvrakMono';

  static ThemeData light() => _build(AppColors.light());

  static ThemeData dark() => _build(AppColors.dark());

  static ThemeData _build(AppColors c) {
    final TextTheme text = _textTheme(c);

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      // Mürekkep damgası dalga efekti değil; dokunma geri bildirimi
      // `Pressable` içinde ölçek + haptik olarak veriliyor.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: c.brightness,
        surface: c.surface,
        onSurface: c.onSurface,
        primary: c.accent,
        onPrimary: c.onAccent,
        error: c.danger,
        onError: c.onDanger,
      ),
      textTheme: text,
      fontFamily: bodyFamily,
      dividerTheme: DividerThemeData(
        color: c.hairline,
        thickness: Dims.hairline,
        space: Dims.hairline,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceInverse,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.onSurfaceInverse),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.allSm),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        showDragHandle: false,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.bodyLarge,
        iconColor: c.onSurfaceMuted,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: Radii.allSm),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: Radii.allSm),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[AppColorsExtension(c)],
    );
  }

  static TextTheme _textTheme(AppColors c) {
    TextStyle display(
      double size, {
      FontWeight weight = FontWeight.w700,
      double tracking = -0.02,
      double height = 1.04,
    }) =>
        TextStyle(
          fontFamily: displayFamily,
          fontSize: size,
          fontWeight: weight,
          color: c.onSurface,
          height: height,
          letterSpacing: size * tracking,
        );

    TextStyle body(
      double size, {
      FontWeight weight = FontWeight.w400,
      Color? color,
      double height = 1.45,
    }) =>
        TextStyle(
          fontFamily: bodyFamily,
          fontSize: size,
          fontWeight: weight,
          color: color ?? c.onSurface,
          height: height,
        );

    /// Künye sesi: küçük, seyrek harflenmiş, büyük harf kullanımına uygun.
    TextStyle mono(
      double size, {
      FontWeight weight = FontWeight.w400,
      Color? color,
      double tracking = 0.09,
    }) =>
        TextStyle(
          fontFamily: monoFamily,
          fontSize: size,
          fontWeight: weight,
          color: color ?? c.onSurfaceMuted,
          height: 1.25,
          letterSpacing: size * tracking,
        );

    return TextTheme(
      // Masthead — kütüphane başlığı.
      displayLarge: display(Prim.textMasthead, tracking: -0.035),
      displayMedium: display(Prim.text3xl, tracking: -0.03),
      displaySmall: display(Prim.text2xl),
      headlineMedium: display(Prim.textXl, height: 1.14),
      headlineSmall: display(Prim.textLg, weight: FontWeight.w600, height: 1.2),

      // Belge adları — serif, editöryel.
      titleLarge: display(Prim.textLg, weight: FontWeight.w600, height: 1.22),
      titleMedium: display(Prim.textMd, weight: FontWeight.w600, height: 1.24),

      bodyLarge: body(Prim.textMd),
      bodyMedium: body(Prim.textSm),
      bodySmall: body(Prim.textXs, color: c.onSurfaceMuted, height: 1.4),

      // Künye ve etiketler — mono.
      labelLarge: mono(Prim.textSm, weight: FontWeight.w700, tracking: 0.06),
      labelMedium: mono(Prim.textXs, weight: FontWeight.w700),
      labelSmall: mono(Prim.textMicro, color: c.onSurfaceFaint, tracking: 0.14),
    );
  }
}
