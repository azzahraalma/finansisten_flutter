import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final auth = AuthService.instance;

  String email = '';
  String password = '';
  bool hidePassword = true;
  bool isLoading = false;
  bool isSendingReset = false;

  OverlayEntry? _snackEntry;

  void showTopSnack(String message, {IconData icon = Icons.info}) {
    _snackEntry?.remove();

    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (_) => _TopSnack(
        message: message,
        icon: icon,
      ),
    );

    _snackEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
      _snackEntry = null;
    });
  }

  Future<void> _sendResetPassword() async {
    final emailTrim = email.trim().toLowerCase();

    if (emailTrim.isEmpty) {
      showTopSnack("Masukkan email terlebih dahulu", icon: Icons.warning_amber_rounded);
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(emailTrim)) {
      showTopSnack("Format email tidak valid", icon: Icons.error);
      return;
    }

    setState(() => isSendingReset = true);

    try {
      await auth.sendPasswordResetEmail(emailTrim);
      if (mounted) {
        showTopSnack(
          "Cek $emailTrim untuk link reset password di inbox atau folder spam",
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnack(e.toString(), icon: Icons.error);
      }
    } finally {
      if (mounted) setState(() => isSendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6DB5FD),
      body: Column(
        children: [
          const SizedBox(height: 100),

          const Text(
            "Masuk",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color.fromARGB(255, 1, 34, 73),
            ),
          ),

          const SizedBox(height: 60),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    labeledInput(
                      label: "Email",
                      hint: "example@email.com",
                      isPassword: false,
                      hidePass: false,
                      onChanged: (v) => email = v,
                      onToggle: null,
                    ),

                    const SizedBox(height: 20),

                    labeledInput(
                      label: "Password",
                      hint: "••••••••",
                      isPassword: true,
                      hidePass: hidePassword,
                      onChanged: (v) => password = v,
                      onToggle: () =>
                          setState(() => hidePassword = !hidePassword),
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isSendingReset ? null : _sendResetPassword,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: isSendingReset
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF6DB5FD),
                                ),
                              )
                            : const Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6DB5FD),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    primaryButton("Masuk", () async {
                      email = email.trim().toLowerCase();
                      password = password.trim();

                      if (email.isEmpty || password.isEmpty) {
                        showTopSnack(
                          "Email dan password wajib diisi",
                          icon: Icons.warning_amber_rounded,
                        );
                        return;
                      }

                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(email)) {
                        showTopSnack(
                          "Format email tidak valid",
                          icon: Icons.error,
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      bool success = await auth.login(email, password);

                      setState(() => isLoading = false);

                      if (success) {
                        showTopSnack(
                          "Login berhasil",
                          icon: Icons.check_circle,
                        );

                        await Future.delayed(const Duration(milliseconds: 500));

                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomePage(),
                            ),
                          );
                        }
                      } else {
                        showTopSnack(
                          "Email atau password salah",
                          icon: Icons.error,
                        );
                      }
                    }),

                    const SizedBox(height: 20),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: "Belum punya akun? ",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: "Daftar",
                                style: TextStyle(
                                  color: Color(0xFF6FA8DC),
                                  fontWeight: FontWeight.bold,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget labeledInput({
    required String label,
    required String hint,
    required bool isPassword,
    required bool hidePass,
    required Function(String) onChanged,
    required VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color.fromARGB(255, 1, 34, 73),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          keyboardType: isPassword
              ? TextInputType.text
              : TextInputType.emailAddress,
          obscureText: isPassword ? hidePass : false,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFB0B0B0), // 🔥 HINT TEXT ABU-ABU TERANG
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFE3F2FD),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      hidePass ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF999999), // 🔥 ICON ABU-ABU
                    ),
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget primaryButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6DB5FD),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 1, 34, 73),
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TopSnack extends StatefulWidget {
  final String message;
  final IconData icon;

  const _TopSnack({
    required this.message,
    required this.icon,
  });

  @override
  State<_TopSnack> createState() => _TopSnackState();
}

class _TopSnackState extends State<_TopSnack>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> slide;
  late Animation<double> fade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );

    fade = Tween<double>(begin: 0, end: 1).animate(controller);

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: const Color(0xFF6DB5FD)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 1, 34, 73),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}