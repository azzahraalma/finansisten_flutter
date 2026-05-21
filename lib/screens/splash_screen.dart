import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../services/local_auth_service.dart';
import 'onboarding_page.dart';
import 'homepage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigate(); // ← FlutterNativeSplash.remove() sudah dipindah ke dalam _navigate()
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    FlutterNativeSplash.remove(); // ← di sini

    final auth = LocalAuthService();
    final isLoggedIn = await auth.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6DB5FD),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              '.idea/assets/img/logo_clear.png',
              width: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'Finansisten',
              style: TextStyle(
                color: Color(0xFF012249),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}