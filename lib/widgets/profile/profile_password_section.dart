import 'package:flutter/material.dart';
import 'profile_constants.dart';

class ProfilePasswordSection extends StatelessWidget {
  const ProfilePasswordSection({
    super.key,
    required this.onGantiPassword,
  });

  final VoidCallback onGantiPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Password",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: kFieldBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '●●●●●●●●',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 4,
                color: kPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onGantiPassword,
          child: const Text(
            "Ganti Password",
            style: TextStyle(
              fontSize: 13,
              color: kAccent,
              decoration: TextDecoration.underline,
              decorationColor: kAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}