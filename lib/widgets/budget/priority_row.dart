import 'package:flutter/material.dart';

class PriorityRow extends StatelessWidget {
  final int urutan;
  final Map<String, dynamic> item;

  const PriorityRow({
    super.key,
    required this.urutan,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF6DB5FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$urutan',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item['kategori_nama'] as String? ?? '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF012249),
              ),
            ),
          ),
        ],
      ),
    );
  }
}