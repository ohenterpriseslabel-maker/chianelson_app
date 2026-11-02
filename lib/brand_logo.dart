import 'package:flutter/material.dart';

/// The CHIANELSON logo. It fades and rises in when shown, then floats gently, like the logo on the website.
class BrandLogo extends StatefulWidget {
  const BrandLogo({super.key, this.height = 44, this.wordmark = false});

  /// Height in pixels. The width follows the logo's proportions.
  final double height;

  /// true shows the logo with the CHIANELSON name underneath; false shows the mark only.
  final bool wordmark;

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.wordmark ? 'assets/images/logo_full.png' : 'assets/images/logo_mark.png';
    final curved = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: Listenable.merge([curved, _float]),
      builder: (context, child) {
        final rise = (1 - curved.value) * 14 - _float.value * 4;
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(offset: Offset(0, rise), child: child),
        );
      },
      child: Image.asset(
        asset,
        height: widget.height,
        semanticLabel: 'CHIANELSON Home Gadgets Limited',
      ),
    );
  }
}