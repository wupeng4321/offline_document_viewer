import 'package:flutter/painting.dart';

import 'primitives.dart';

/// Boşluk ölçeği — 4pt tabanlı.
abstract final class Space {
  static const double none = Prim.space0;
  static const double xxs = Prim.space1;
  static const double xs = Prim.space2;
  static const double sm = Prim.space3;
  static const double md = Prim.space4;
  static const double lg = Prim.space5;
  static const double xl = Prim.space6;
  static const double xxl = Prim.space8;
  static const double xxxl = Prim.space10;
  static const double huge = Prim.space12;
  static const double giant = Prim.space16;
}

/// Köşe yarıçapları.
///
/// Arşiv estetiği köşeleri sevmez: varsayılan keskin. Yuvarlaklık yalnızca
/// dokunulan yüzeylerde ve orada da az.
abstract final class Radii {
  static const Radius none = Radius.zero;
  static const Radius xs = Radius.circular(Prim.radiusXs);
  static const Radius sm = Radius.circular(Prim.radiusSm);
  static const Radius md = Radius.circular(Prim.radiusMd);
  static const Radius full = Radius.circular(Prim.radiusFull);

  static const BorderRadius allNone = BorderRadius.zero;
  static const BorderRadius allXs = BorderRadius.all(xs);
  static const BorderRadius allSm = BorderRadius.all(sm);
  static const BorderRadius allMd = BorderRadius.all(md);
  static const BorderRadius allFull = BorderRadius.all(full);
}

/// Bileşen bazlı ölçüler.
abstract final class Dims {
  /// Dokunma hedefi alt sınırı — erişilebilirlik gereği.
  static const double minTapTarget = 48;

  /// Biçim damgası (kare mühür).
  static const double stamp = 40;
  static const double stampLarge = 64;

  /// Fişleme satırının sol renk sırtı.
  static const double spine = Prim.spine;

  /// Satırdaki sıra numarası sütunu.
  static const double indexColumn = 34;

  static const double viewerChromeHeight = 56;
  static const double hairline = Prim.hairline;
  static const double borderThick = Prim.borderThick;

  /// İçerik genişliği tavanı — tablette satır uzunluğunu okunur tutar.
  static const double contentMaxWidth = 720;
}
