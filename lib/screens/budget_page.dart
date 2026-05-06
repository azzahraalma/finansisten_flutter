import 'package:flutter/material.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Budget Page",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF012249)),
        ),
      ),
    );
  }
}