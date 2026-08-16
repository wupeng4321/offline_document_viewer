import 'package:flutter/painting.dart';

/// Ham tasarım değerleri — paletin ve ölçeklerin tek kaynağı.
///
/// **Bu dosya widget'lardan doğrudan kullanılmaz.** Yalnızca `semantic.dart`
/// buradan okur (bkz. `docs/plans/01_temel_iskele.md`).
///
/// Estetik yön: **arşiv/matbaa**. Saf beyaz ve saf siyah yok; kâğıt kremi ve
/// mürekkep siyahı var. Nötr eksen sıcak tarafa kaydırılmış — ekranda kâğıt
/// hissi veren şey tam olarak bu sapma.
abstract final class Prim {
  // ── mürekkep ekseni — sıcak siyah ─────────────────────────────────────
  static const Color ink0 = Color(0xFF0C0B0A); // en koyu yüzey
  static const Color ink1 = Color(0xFF15130F);
  static const Color ink2 = Color(0xFF1F1C17);
  static const Color ink3 = Color(0xFF2C2820);
  static const Color ink4 = Color(0xFF3E392F);
  static const Color ink5 = Color(0xFF5C5648);
  static const Color ink6 = Color(0xFF8A8272);
  static const Color ink7 = Color(0xFFB5AD9B);
  static const Color ink8 = Color(0xFFD8D1C1);

  // ── kâğıt ekseni — krem ───────────────────────────────────────────────
  static const Color paper0 = Color(0xFFF6F2E9); // ana kâğıt
  static const Color paper1 = Color(0xFFFDFBF5); // kabartılmış kâğıt
  static const Color paper2 = Color(0xFFEDE7DA); // gömülü / oluk

  // ── akçil, yalnızca belge yüzeyinde ──────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);

  // ── vurgu — damga kırmızısı ───────────────────────────────────────────
  // Arşivde damga tek renktir ve gözü o yönetir; marka rengi bu.
  static const Color stamp = Color(0xFFC2361B);
  static const Color stampBright = Color(0xFFE0512F);
  static const Color stampMuted = Color(0xFF3A1B12);
  static const Color stampWash = Color(0xFFF7E2DC);

  // ── durum ─────────────────────────────────────────────────────────────
  static const Color amber = Color(0xFFB57A12);
  static const Color amberWash = Color(0xFFF6E9CC);
  static const Color green = Color(0xFF3E6B3A);

  // ── biçim kimlik renkleri ─────────────────────────────────────────────
  // Office'in renk dili; kullanıcı rozeti tanıyor. Hafifçe kısılmış tonlar,
  // krem zeminde parlak orijinaller cırtlak duruyor.
  static const Color fmtPdf = Color(0xFFC0392B);
  static const Color fmtWord = Color(0xFF2A5699);
  static const Color fmtExcel = Color(0xFF1E6B43);
  static const Color fmtPowerPoint = Color(0xFFC0451F);
  static const Color fmtText = Color(0xFF5C5648);

  // ── boşluk — 4pt tabanlı ──────────────────────────────────────────────
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // ── yarıçap ───────────────────────────────────────────────────────────
  // Arşiv estetiği köşeleri sevmez: neredeyse her şey keskin. Yuvarlaklık
  // yalnızca dokunulan yüzeylerde ve orada da az.
  static const double radiusNone = 0;
  static const double radiusXs = 2;
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusFull = 999;

  // ── tip ölçeği — geniş kontrast ───────────────────────────────────────
  // Küçük künye ile dev başlık arasındaki fark bilerek büyük; editöryel
  // sayfanın ritmi bu kontrastdan geliyor.
  static const double textMicro = 10;
  static const double textXs = 11;
  static const double textSm = 13;
  static const double textMd = 15;
  static const double textLg = 18;
  static const double textXl = 23;
  static const double text2xl = 30;
  static const double text3xl = 40;
  static const double textMasthead = 56;

  // ── süre (ms) ─────────────────────────────────────────────────────────
  static const int durInstant = 90;
  static const int durQuick = 180;
  static const int durStandard = 280;
  static const int durEmphasized = 420;
  static const int durSlow = 640;

  // ── çizgi ─────────────────────────────────────────────────────────────
  static const double hairline = 1;
  static const double borderThick = 2;

  /// Biçim sırtının kalınlığı — fişleme satırının kimliği.
  static const double spine = 5;
}
