import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../database/database_helper.dart';
import '../services/local_auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

bool showPassword = false;

class _ProfilePageState extends State<ProfilePage> {
  final db = DatabaseHelper.instance;
  final auth = LocalAuthService();

  Map<String, dynamic>? userData;

  bool isLoading = true;
  bool isEditingUsername = false;
  bool isEditingEmail = false;

  final usernameController = TextEditingController();
  final emailController = TextEditingController();

  String? profileImagePath;

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ================= LOAD USER =================

  Future<void> _loadUser() async {
    final userId = await auth.getUserId();

    if (userId == null) return;

    final db2 = await db.database;

    final result = await db2.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      setState(() {
        userData = result.first;

        usernameController.text =
            userData!['username'].toString();

        emailController.text =
            userData!['email'].toString();

        isLoading = false;
      });
    }
  }

  // ================= PICK IMAGE =================

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (picked != null) {
      setState(() {
        profileImagePath = picked.path;
      });
    }
  }

  // ================= UPDATE PROFILE =================

Future<void> _updateProfil() async {
  final userId = await auth.getUserId();

  if (userId == null) return;

  final username = usernameController.text.trim();
  final email = emailController.text.trim();

  if (username.isEmpty) {
    _showTopSnack(
      "Username tidak boleh kosong",
      isError: true,
    );
    return;
  }

  if (email.isEmpty) {
    _showTopSnack(
      "Email tidak boleh kosong",
      isError: true,
    );
    return;
  }

  final emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  if (!emailRegex.hasMatch(email)) {
    _showTopSnack(
      "Format email tidak valid",
      isError: true,
    );
    return;
  }

  await db.updateUser({
    'id': userId,
    'username': username,
    'email': email,
  });

  setState(() {
    userData = {
      ...?userData,
      'username': username,
      'email': email,
    };

    isEditingUsername = false;
    isEditingEmail = false;
  });

  _showTopSnack("Profil berhasil diperbarui");
}

  // ================= TOP SNACK =================

  void _showTopSnack(
    String msg, {
    bool isError = false,
  }) {
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
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red
                  : const Color(0xFF4A90D9),
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

    Future.delayed(
      const Duration(seconds: 2),
      () {
        entry.remove();
      },
    );
  }

  // ================= DIALOG GANTI PASSWORD =================

  void _showGantiPasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController =
        TextEditingController();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ganti Password",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF012249),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pop(ctx),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration:
                                const BoxDecoration(
                              color: Color(0xFFE3F2FD),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF012249),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // PASSWORD LAMA
                    const Text(
                      "Password Lama",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF012249),
                      ),
                    ),

                    const SizedBox(height: 8),

                    _passwordField(
                      controller: oldPassController,
                      obscure: obscureOld,
                      onToggle: () {
                        setDialog(() {
                          obscureOld = !obscureOld;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // PASSWORD BARU
                    const Text(
                      "Password Baru",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF012249),
                      ),
                    ),

                    const SizedBox(height: 8),

                    _passwordField(
                      controller: newPassController,
                      obscure: obscureNew,
                      onToggle: () {
                        setDialog(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // KONFIRMASI
                    const Text(
                      "Konfirmasi Password",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF012249),
                      ),
                    ),

                    const SizedBox(height: 8),

                    _passwordField(
                      controller:
                          confirmPassController,
                      obscure: obscureConfirm,
                      onToggle: () {
                        setDialog(() {
                          obscureConfirm =
                              !obscureConfirm;
                        });
                      },
                    ),

                    const SizedBox(height: 28),

                    // BUTTON
                    Center(
                      child: SizedBox(
                        width: 210,
                        child: ElevatedButton(
                          onPressed: () async {
                            final oldPass =
                                oldPassController.text
                                    .trim();

                            final newPass =
                                newPassController.text
                                    .trim();

                            final confirmPass =
                                confirmPassController
                                    .text
                                    .trim();

                            final currentPassword =
                                userData?['password']
                                        ?.toString() ??
                                    '';

                            // VALIDASI
                            if (oldPass.isEmpty ||
                                newPass.isEmpty ||
                                confirmPass.isEmpty) {
                              _showTopSnack(
                                "Isi semua field password",
                                isError: true,
                              );
                              return;
                            }

                            // PASSWORD LAMA
                            if (oldPass !=
                                currentPassword) {
                              _showTopSnack(
                                "Password lama salah",
                                isError: true,
                              );
                              return;
                            }

                            // PASSWORD COCOK
                            if (newPass !=
                                confirmPass) {
                              _showTopSnack(
                                "Password tidak cocok",
                                isError: true,
                              );
                              return;
                            }

                            // MINIMAL
                            if (newPass.length < 6) {
                              _showTopSnack(
                                "Password minimal 6 karakter",
                                isError: true,
                              );
                              return;
                            }

                            final userId =
                                await auth.getUserId();

                            if (userId == null) return;

                            await db.updateUser({
                              'id': userId,
                              'password': newPass,
                            });

                            setState(() {
                              userData = {
                                ...?userData,
                                'password': newPass,
                              };
                            });

                            Navigator.pop(ctx);

                            _showTopSnack(
                              "Password berhasil diperbarui",
                            );
                          },
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                                    0xFF4A90D9),
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(30),
                            ),
                          ),
                          child: const Text(
                            "Simpan Password",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= PASSWORD FIELD =================

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      height: 50,
      padding:
          const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF012249),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Masukkan password",
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF6DB5FD),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ================= LOGOUT =================

  void _logout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Keluar Akun?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012249),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Kamu yakin ingin logout dari akun ini?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(ctx),
                        style:
                            OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF6DB5FD),
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(30),
                          ),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            color: Color(0xFF012249),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);

                          await auth.logout();

                          if (!mounted) return;

                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red,
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(30),
                          ),
                        ),
                        child: const Text(
                          "Keluar",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6DB5FD),
        ),
      );
    }

    final username =
        userData?['username']?.toString() ?? '-';

    final email =
        userData?['email']?.toString() ?? '-';

    final password =
        userData?['password']?.toString() ?? '';

    final passwordDots = List.generate(
      password.length,
      (_) => '●',
    ).join(' ');

    return Scaffold(
      backgroundColor: const Color(0xFF6DB5FD),

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // HEADER
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Text(
                "Profil",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012249),
                ),
              ),
            ),

            // AVATAR
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD6EAFF),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      image: profileImagePath != null
                          ? DecorationImage(
                              image: FileImage(
                                File(profileImagePath!),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: profileImagePath == null
                        ? const Icon(
                            Icons.person,
                            size: 82,
                            color: Color(0xFF6DB5FD),
                          )
                        : null,
                  ),

                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A90D9),
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
                color: Color(0xFF012249),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              email,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF012249),
              ),
            ),

            const SizedBox(height: 18),

            // BODY PUTIH
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
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    28,
                    20,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // USERNAME
                      const Text(
                        "Username",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF012249),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: usernameController,
                                enabled: isEditingUsername,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF012249),
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Masukkan username",
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isEditingUsername =
                                      !isEditingUsername;
                                });
                              },
                              child: Icon(
                                isEditingUsername
                                    ? Icons.check
                                    : Icons.edit_outlined,
                                color: const Color(0xFF6DB5FD),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                    // EMAIL
                    const Text(
                      "Email",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF012249),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: emailController,
                              enabled: isEditingEmail,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF012249),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isEditingEmail = !isEditingEmail;
                              });
                            },
                            child: Icon(
                              isEditingEmail
                                  ? Icons.check
                                  : Icons.edit_outlined,
                              color: const Color(0xFF6DB5FD),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                      // PASSWORD
                      const Text(
                        "Password",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF012249),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                showPassword
                                    ? password
                                    : passwordDots,
                                style: const TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 2,
                                  color: Color(0xFF012249),
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                              child: Icon(
                                showPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: const Color(0xFF6DB5FD),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: _showGantiPasswordDialog,
                        child: const Text(
                          "Ganti Password",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6DB5FD),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF6DB5FD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // UPDATE BUTTON
                      Center(
                        child: SizedBox(
                          width: 210,
                          child: ElevatedButton(
                            onPressed:
                                _updateProfil,
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                      0xFF4A90D9),
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 14,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            30),
                              ),
                            ),
                            child: const Text(
                              "Update Profil",
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // LOGOUT BUTTON
                      Center(
                        child: SizedBox(
                          width: 210,
                          child:
                              OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 18,
                            ),
                            label: const Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            style:
                                OutlinedButton
                                    .styleFrom(
                              side:
                                  const BorderSide(
                                color: Colors.red,
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 14,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            30),
                              ),
                            ),
                          ),
                        ),
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