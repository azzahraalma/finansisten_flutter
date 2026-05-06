import 'package:flutter/material.dart';
import '../services/local_auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final auth = LocalAuthService();

  String email = '';
  String password = '';
  String confirm = '';
  bool hidePassword = true;
  bool hideConfirm = true;
  bool isLoading = false; // 🔥 tambahan

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6DB5FD),
      body: Column(
        children: [
          SizedBox(height: 80),
          Text(
            "Daftar",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 1, 34, 73),
            ),
          ),
          SizedBox(height: 40),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),

                    /// EMAIL
                    labeledInput(
                      label: "Email",
                      hint: "example@example.com",
                      isPassword: false,
                      hidePass: false,
                      onChanged: (v) => email = v,
                      onToggle: null,
                    ),

                    SizedBox(height: 20),

                    /// PASSWORD
                    labeledInput(
                      label: "Password",
                      hint: "••••••••",
                      isPassword: true,
                      hidePass: hidePassword,
                      onChanged: (v) => password = v,
                      onToggle: () => setState(
                          () => hidePassword = !hidePassword),
                    ),

                    SizedBox(height: 20),

                    /// CONFIRM PASSWORD
                    labeledInput(
                      label: "Konfirmasi Password",
                      hint: "••••••••",
                      isPassword: true,
                      hidePass: hideConfirm,
                      onChanged: (v) => confirm = v,
                      onToggle: () => setState(
                          () => hideConfirm = !hideConfirm),
                    ),

                    SizedBox(height: 20),

                    Center(
                      child: Text(
                        "Dengan melanjutkan, kamu setuju dengan\nTerms of Use dan Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: const Color.fromARGB(255, 0, 0, 0)),
                      ),
                    ),

                    SizedBox(height: 20),

                    /// BUTTON DAFTAR
                    primaryButton("Daftar", () async {
                      // 🔥 rapihin input
                      email = email.trim().toLowerCase();
                      password = password.trim();
                      confirm = confirm.trim();

                      // ❌ validasi kosong
                      if (email.isEmpty ||
                          password.isEmpty ||
                          confirm.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text("Semua field wajib diisi")),
                        );
                        return;
                      }

                      // ❌ validasi email
                      final emailRegex =
                          RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text("Format email tidak valid")),
                        );
                        return;
                      }

                      // ❌ password minimal
                      if (password.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Password minimal 6 karakter")),
                        );
                        return;
                      }

                      // ❌ konfirmasi password
                      if (password != confirm) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text("Password tidak sama")),
                        );
                        return;
                      }

                      // 🔄 loading ON
                      setState(() => isLoading = true);

                      bool success =
                          await auth.register(email, password);

                      // 🔄 loading OFF
                      setState(() => isLoading = false);

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Registrasi berhasil! Silakan login")),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text("Email sudah terdaftar")),
                        );
                      }
                    }),

                    SizedBox(height: 10),

                    /// GOOGLE ICON
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            "G",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    /// FOOTER
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Sudah Punya Akun? ",
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () =>
                                    Navigator.pop(context),
                                child: Text(
                                  "Masuk",
                                  style: TextStyle(
                                    color: Color(0xFF6FA8DC),
                                    fontSize: 13,
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

  /// INPUT FIELD
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
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: const Color.fromARGB(255, 1, 34, 73),
            ),
          ),
        ),
        SizedBox(height: 6),
        TextField(
          keyboardType: isPassword
              ? TextInputType.text
              : TextInputType.emailAddress,
          obscureText: isPassword ? hidePass : false,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Color(0xFFE3F2FD),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      hidePass
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  /// BUTTON
  Widget primaryButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 80),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6DB5FD),
            shape: StadiumBorder(),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  text,
                  style: TextStyle(
                    color:
                        const Color.fromARGB(255, 1, 34, 73),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}