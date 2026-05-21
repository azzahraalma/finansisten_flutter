import 'package:flutter/material.dart';
import 'package:finansisten/database/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/terms_overlay.dart';
import 'homepage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final auth = AuthService.instance;
  final db = FirestoreService.instance;

  String username = '';
  String email = '';
  String password = '';
  String confirm = '';
  bool hidePassword = true;
  bool hideConfirm = true;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6DB5FD),
      body: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            "Daftar",
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    labeledInput(
                      label: "Username",
                      hint: "nama kamu",
                      isPassword: false,
                      hidePass: false,
                      onChanged: (v) => username = v,
                      onToggle: null,
                    ),

                    const SizedBox(height: 20),

                    labeledInput(
                      label: "Email",
                      hint: "example@example.com",
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

                    const SizedBox(height: 20),

                    labeledInput(
                      label: "Konfirmasi Password",
                      hint: "••••••••",
                      isPassword: true,
                      hidePass: hideConfirm,
                      onChanged: (v) => confirm = v,
                      onToggle: () =>
                          setState(() => hideConfirm = !hideConfirm),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.6,
                          ),
                          children: [
                            const TextSpan(
                                text:
                                    'Dengan melanjutkan, kamu setuju dengan\n'),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => showTermsOverlay(context),
                                child: const Text(
                                  'Syarat & Ketentuan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF012249),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' dan '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => showTermsOverlay(context),
                                child: const Text(
                                  'Kebijakan Privasi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF012249),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    primaryButton("Daftar", () async {
                      username = username.trim();
                      email = email.trim().toLowerCase();
                      password = password.trim();
                      confirm = confirm.trim();

                      if (username.isEmpty ||
                          email.isEmpty ||
                          password.isEmpty ||
                          confirm.isEmpty) {
                        _showSnack("Semua field wajib diisi");
                        return;
                      }

                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(email)) {
                        _showSnack("Format email tidak valid");
                        return;
                      }

                      if (password.length < 6) {
                        _showSnack("Password minimal 6 karakter");
                        return;
                      }

                      if (password != confirm) {
                        _showSnack("Password tidak sama");
                        return;
                      }

                      setState(() => isLoading = true);

                      final success = await auth.register(email, password);

                      if (success) {
                        final uid = auth.getUserId();
                        if (uid != null) {
                          await db.saveUserProfile(uid, {
                            'username': username,
                            'email': email,
                            'password_length': password.length,
                          });
                        }
                        setState(() => isLoading = false);
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                          (route) => false,
                        );
                      } else {
                        setState(() => isLoading = false);
                        _showSnack("Email sudah terdaftar");
                      }
                    }),

                    const SizedBox(height: 15),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Sudah Punya Akun? ",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  "Masuk",
                                  style: TextStyle(
                                    color: Color(0xFF6FA8DC),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
              : label == "Email"
                  ? TextInputType.emailAddress
                  : TextInputType.text,
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
                      size: 20,
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
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}