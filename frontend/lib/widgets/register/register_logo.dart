import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegisterLogo extends StatelessWidget {
  const RegisterLogo({
    this.heightFactor = 0.24,
    this.widthFactor = 0.28,
    super.key,
  });

  final double heightFactor;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return SizedBox(
      height: screenSize.height * heightFactor,
      child: Center(
        child: SvgPicture.asset(
          'assets/images/recipy-logo.svg',
          width: screenSize.width * widthFactor,
          height: screenSize.width * widthFactor,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
