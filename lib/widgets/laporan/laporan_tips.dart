import 'package:flutter/material.dart';
import 'laporan_constants.dart';

class TipsButton extends StatelessWidget {
  const TipsButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.only(top: 6, bottom: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: kPrimary),
            SizedBox(width: 6),
            Text(
              "Tips Keuangan",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TipsPopup extends StatelessWidget {
  const TipsPopup({super.key, required this.tips, required this.visible});

  final String tips;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1 : 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: kAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tips,
                style: const TextStyle(
                  fontSize: 13,
                  color: kPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}