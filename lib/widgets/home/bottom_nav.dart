import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _icons = [
    Icons.credit_card,
    Icons.calculate_outlined,
    Icons.list_alt_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 201, 232, 255),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(45),
          topRight: Radius.circular(45),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (i) {
          final isActive = currentIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF6DB5FD) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(_icons[i], color: const Color(0xFF012249), size: 38),
              ),
            ),
          );
        }),
      ),
    );
  }
}