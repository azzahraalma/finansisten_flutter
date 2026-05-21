import 'package:flutter/material.dart';
import 'laporan_constants.dart';

class LaporanSummaryRow extends StatelessWidget {
  const LaporanSummaryRow({
    super.key,
    required this.pemasukan,
    required this.pengeluaran,
    required this.sisa,
  });

  final double pemasukan;
  final double pengeluaran;
  final double sisa;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LaporanSummaryCard(
          label: "Pengeluaran",
          amount: pengeluaran,
          icon: Icons.arrow_outward,
          color: kPrimary,
        ),
        const SizedBox(width: 8),
        LaporanSummaryCard(
          label: "Pemasukan",
          amount: pemasukan,
          icon: Icons.south_west,
          color: kAccent,
        ),
        const SizedBox(width: 8),
        LaporanSisaCard(sisa: sisa),
      ],
    );
  }
}

class LaporanSummaryCard extends StatelessWidget {
  const LaporanSummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatRupiah(amount),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LaporanSisaCard extends StatelessWidget {
  const LaporanSisaCard({super.key, required this.sisa});

  final double sisa;

  @override
  Widget build(BuildContext context) {
    final isPositive = sisa >= 0;
    final color = isPositive ? const Color(0xFF1565C0) : Colors.red.shade400;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPositive
                    ? Icons.savings_outlined
                    : Icons.warning_amber_outlined,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Saldo",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatRupiah(sisa.abs()),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}