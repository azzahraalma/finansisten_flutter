import 'package:flutter/material.dart';
import 'profile_constants.dart';

class ProfileFieldInput extends StatelessWidget {
  const ProfileFieldInput({
    super.key,
    required this.label,
    required this.controller,
    required this.isEditing,
    required this.onToggle,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onToggle;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: isEditing,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 16, color: kPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Masukkan ${label.toLowerCase()}",
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  isEditing ? Icons.check : Icons.edit_outlined,
                  color: kAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}