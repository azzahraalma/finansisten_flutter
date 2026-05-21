import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/firestore_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'package:finansisten/widgets/profile/profile_constants.dart';
import 'package:finansisten/widgets/profile/profile_avatar.dart';
import 'package:finansisten/widgets/profile/profile_field_input.dart';
import 'package:finansisten/widgets/profile/profile_action_buttons.dart';
import 'package:finansisten/widgets/profile/ganti_password_dialog.dart';
import 'package:finansisten/widgets/profile/logout_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthService.instance;
  final _db = FirestoreService.instance;

  Map<String, dynamic>? userData;

  bool isLoading = true;
  bool isEditingUsername = false;
  bool isEditingEmail = false;

  final usernameController = TextEditingController();
  final emailController = TextEditingController();

  int passwordLength = 0;

  String? profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProfileImage();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = _auth.getUserId();
    if (uid == null) return;

    final result = await _db.getUserProfile(uid);
    if (result != null) {
      final cleaned = {
        ...result,
        'username': result['username']?.toString().trim() ?? '',
        'email': result['email']?.toString().trim() ?? '',
      };

      setState(() {
        userData = cleaned;
        usernameController.text = cleaned['username'];
        emailController.text = cleaned['email'];
        passwordLength = (result['password_length'] as num?)?.toInt() ?? 8;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadProfileImage() async {
    final path = await _auth.getProfileImage();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        setState(() => profileImagePath = path);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (picked != null) {
      await _auth.saveProfileImage(picked.path);
      setState(() => profileImagePath = picked.path);
    }
  }

  Future<void> _updateProfil() async {
    final uid = _auth.getUserId();
    if (uid == null) return;

    final username = usernameController.text.trim();
    final email = emailController.text.trim();

    if (username.isEmpty) {
      _showTopSnack("Username tidak boleh kosong", isError: true);
      return;
    }

    if (email.isEmpty) {
      _showTopSnack("Email tidak boleh kosong", isError: true);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showTopSnack("Format email tidak valid", isError: true);
      return;
    }

    await _db.updateUserProfile(uid, {'username': username, 'email': email});

    setState(() {
      userData = {...?userData, 'username': username, 'email': email};
      isEditingUsername = false;
      isEditingEmail = false;
    });

    _showTopSnack("Profil berhasil diperbarui");
  }

  void _showGantiPasswordDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => GantiPasswordDialog(
        onSave: (newPassword) async {
          final uid = _auth.getUserId();
          if (uid == null) return;

          await _db.updateUserProfile(uid, {
            'password_length': newPassword.length,
          });

          setState(() {
            passwordLength = newPassword.length;
          });

          _showTopSnack("Password berhasil diperbarui");
        },
        onError: (msg) => _showTopSnack(msg, isError: true),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => LogoutDialog(
        onConfirm: () async {
          await _auth.logout();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        },
      ),
    );
  }

  void _showTopSnack(String msg, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 70,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isError ? Colors.red : kBlue,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kAccent),
      );
    }

    final username = userData?['username']?.toString().trim() ?? '-';
    final email = userData?['email']?.toString().trim() ?? '-';

    final passwordBullets = '●' * passwordLength;

    return Scaffold(
      backgroundColor: kAccent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                "Profil",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
            ),

            ProfileAvatar(
              profileImagePath: profileImagePath,
              username: username,
              email: email,
              onTap: _pickImage,
            ),

            const SizedBox(height: 18),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileFieldInput(
                        label: "Username",
                        controller: usernameController,
                        isEditing: isEditingUsername,
                        onToggle: () => setState(
                            () => isEditingUsername = !isEditingUsername),
                      ),

                      const SizedBox(height: 20),

                      ProfileFieldInput(
                        label: "Email",
                        controller: emailController,
                        isEditing: isEditingEmail,
                        keyboardType: TextInputType.emailAddress,
                        onToggle: () =>
                            setState(() => isEditingEmail = !isEditingEmail),
                      ),

                      const SizedBox(height: 20),

                      _PasswordDisplayField(
                        bullets: passwordBullets,
                        onGantiPassword: _showGantiPasswordDialog,
                      ),

                      const SizedBox(height: 24),

                      ProfileActionButtons(
                        onUpdate: _updateProfil,
                        onLogout: _logout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordDisplayField extends StatelessWidget {
  const _PasswordDisplayField({
    required this.bullets,
    required this.onGantiPassword,
  });

  final String bullets;
  final VoidCallback onGantiPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Password",
          style: TextStyle(
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
                child: Text(
                  bullets.isEmpty ? '––––––––' : bullets,
                  style: TextStyle(
                    fontSize: bullets.isEmpty ? 16 : 10,
                    color: kPrimary,
                    letterSpacing: bullets.isEmpty ? 0 : 2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onGantiPassword,
                child: const Text(
                  "Ganti",
                  style: TextStyle(
                    color: kAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}