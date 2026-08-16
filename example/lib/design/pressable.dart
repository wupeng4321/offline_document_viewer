import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Basma geri bildirimi olan dokunma alanı.
///
/// Sessiz arayüz hata sayılıyor: dokunulan her şey ölçek + haptik ile cevap
/// verir (bkz. `docs/plans/01_temel_iskele.md`). Süre ve eğri token'dan gelir;
/// hiçbir çağıran kendi değerini uydurmaz.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onPressed,
    this.onLongPress,
    this.scale = 0.972,
    this.semanticLabel,
    this.onPressChanged,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// Basılıyken küçülme oranı. Büyük yüzeylerde daha az, küçük hedeflerde
  /// daha çok küçültmek doğru hissi veriyor.
  final double scale;

  final String? semanticLabel;

  /// Basılı durum değişimini dışarı bildirir.
  ///
  /// Bazı bileşenler ölçekten fazlasını yapıyor — fişleme satırı basılıyken
  /// biçim sırtını kalınlaştırıyor. Geri bildirimi tek yerde toplamak yerine
  /// durumu paylaşıyoruz.
  final ValueChanged<bool>? onPressChanged;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down == value) {
      return;
    }
    setState(() => _down = value);
    widget.onPressChanged?.call(value);
    if (value) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setDown(true) : null,
        onTapUp: enabled ? (_) => _setDown(false) : null,
        onTapCancel: enabled ? () => _setDown(false) : null,
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!.call();
              },
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Motion.respecting(context, Motion.instant),
          curve: Motion.easeOut,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.5,
            duration: Motion.respecting(context, Motion.quick),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Listeye kademeli giriş veren sarmalayıcı.
///
/// İlk ekranı dolduran elemanlar sırayla yükselir; sonrakiler gecikmesiz
/// gelir (uzun listede son eleman saniyeler sonra görünmesin diye).
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.standard,
  );

  bool _started = false;

  /// Başlatma `didChangeDependencies` içinde, `initState`'te değil.
  ///
  /// Gecikme ve süre `MediaQuery`den geliyor (hareketi azalt ayarı); MediaQuery
  /// `initState` sırasında okunamaz — okumaya çalışmak sessizce patlıyor ve
  /// animasyon hiç başlamıyordu: içerik kalıcı olarak 0 opaklıkta kalıyordu.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    unawaited(_start());
  }

  Future<void> _start() async {
    final Duration delay = Motion.staggerFor(context, widget.index);
    _controller.duration = Motion.respecting(context, Motion.standard);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (mounted) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = Motion.easeOut.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
