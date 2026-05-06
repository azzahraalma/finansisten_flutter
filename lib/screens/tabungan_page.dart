import 'package:flutter/material.dart';

class TabunganPage extends StatelessWidget {
  const TabunganPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Tabungan Page",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF012249)),
        ),
      ),
    );
  }
}