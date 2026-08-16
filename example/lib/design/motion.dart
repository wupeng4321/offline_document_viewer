import 'package:flutter/widgets.dart';

import 'primitives.dart';

/// Hareket sözleşmesi.
///
/// Hiçbir widget kendi süresini veya eğrisini uydurmaz — hepsi buradan gelir.
/// Sessiz arayüz hata sayılır: her basılabilir bileşen geri bildirim verir,
/// her ekranın girişi vardır (bkz. `docs/plans/01_temel_iskele.md`).
abstract final class Motion {
  /// Basma geri bildirimi — kullanıcı dokunduğunu hissetmeli.
  static const Duration instant = Duration(milliseconds: Prim.durInstant);

  /// Durum değişimi, vurgu, küçük geçişler.
  static const Duration quick = Duration(milliseconds: Prim.durQuick);

  /// Ekran içi geçişler, açılır paneller.
  static const Duration standard = Duration(milliseconds: Prim.durStandard);

  /// Sayfa geçişi, paylaşılan eleman, alt sayfa.
  static const Duration emphasized = Duration(milliseconds: Prim.durEmphasized);

  /// İskelet → içerik gibi büyük ve nadir geçişler.
  static const Duration slow = Duration(milliseconds: Prim.durSlow);

  /// Genel amaçlı çıkış eğrisi — hızlı başlar, yumuşak durur.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Vurgulu geçişler; sonda belirgin bir yavaşlama bırakır.
  static const Curve emphasizedCurve = Curves.easeOutQuint;

  /// İki yönlü hareket (aç/kapa).
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// Yaylanma — yalnızca olumlu geri bildirimde (sabitleme gibi).
  static const Curve spring = Curves.elasticOut;

  /// Kademeli giriş için sıra gecikmesi.
  static const Duration stagger = Duration(milliseconds: 40);

  /// Kademeli girişte animasyon uygulanacak azami eleman sayısı.
  ///
  /// Uzun listelerde her elemanı geciktirmek son elemanı saniyeler sonra
  /// gösterir; ilk ekranı doldurmak yeterli.
  static const int staggerLimit = 8;

  /// Sistemde "hareketi azalt" açıksa animasyonlar tek noktadan kapanır.
  ///
  /// Widget'ların tek tek kontrol etmesi yerine süreler buradan geçirilir.
  static Duration respecting(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
          ? Duration.zero
          : duration;

  /// Sıradaki elemanın kademeli gecikmesi.
  static Duration staggerFor(BuildContext context, int index) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return Duration.zero;
    }
    final int capped = index < staggerLimit ? index : staggerLimit;
    return stagger * capped;
  }
}
