import 'package:flutter/material.dart';

class RegisterTerms extends StatelessWidget {
  const RegisterTerms({
    required this.accepted,
    required this.onChanged,
    super.key,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: accepted,
          activeColor: const Color(0xFFF20D13),
          visualDensity: VisualDensity.compact,
          onChanged: (value) => onChanged(value ?? false),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 7, left: 6),
            child: Text.rich(
              TextSpan(
                text: 'I agree with the ',
                children: [
                  TextSpan(
                    text: 'User Agreement',
                    style: TextStyle(
                      color: Color(0xFFF20D13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFFF20D13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
