import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Center(
        child: SvgPicture.asset(
          'assets/images/recipy-logo.svg',
          width: 112,
          height: 112,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
