import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MelonLogo extends StatelessWidget {
  const MelonLogo({
    super.key,
    this.size = 28,
    this.withGlow = true,
  });

  final double size;
  final bool withGlow;

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      'assets/logo/melon_logo.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!withGlow) {
      return logo;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF56F2A9).withValues(alpha: 0.24),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: logo,
    );
  }
}
