import 'package:flutter/material.dart';
import 'profile_constants.dart';

class ProfilePasswordField extends StatelessWidget {
  const ProfilePasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kFieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(fontSize: 14, color: kPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Masukkan password",
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: kAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}