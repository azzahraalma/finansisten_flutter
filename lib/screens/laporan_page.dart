import 'package:flutter/material.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Laporan Page",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF012249)),
        ),
      ),
    );
  }
}