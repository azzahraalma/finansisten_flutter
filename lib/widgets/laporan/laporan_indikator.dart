import 'package:flutter/material.dart';
import 'laporan_constants.dart';

class IndikatorBulanLalu extends StatelessWidget {
  const IndikatorBulanLalu({super.key, required this.selisih});

  final double selisih;

  @override
  Widget build(BuildContext context) {
    final isHemat = selisih <= 0;
    final color = isHemat ? const Color(0xFF1565C0) : Colors.red.shade400;
    final icon = isHemat ? Icons.trending_down : Icons.trending_up;
    final label = isHemat
        ? "Hemat ${formatRupiah(selisih.abs())} dari bulan lalu"
        : "Lebih boros ${formatRupiah(selisih.abs())} dari bulan lalu";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}