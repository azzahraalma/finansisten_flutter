import 'package:flutter/material.dart';
import '../services/local_auth_service.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  final auth = LocalAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await auth.logout();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
            );
          },
          child: Text("Logout"),
        ),
      ),
    );
  }
}