import 'dart:io';
import 'package:flutter/material.dart';
import 'profile_constants.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profileImagePath,
    required this.username,
    required this.email,
    required this.onTap,
  });

  final String? profileImagePath;
  final String username;
  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD6EAFF),
                  border: Border.all(color: Colors.white, width: 3),
                  image: profileImagePath != null
                      ? DecorationImage(
                          image: FileImage(File(profileImagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profileImagePath == null
                    ? const Icon(Icons.person, size: 82, color: kAccent)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: kBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          username,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: const TextStyle(fontSize: 16, color: kPrimary),
        ),
      ],
    );
  }
}