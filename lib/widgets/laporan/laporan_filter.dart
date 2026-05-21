import 'package:flutter/material.dart';
import 'laporan_constants.dart';

class LaporanFilterRow extends StatelessWidget {
  const LaporanFilterRow({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final String filter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LaporanFilterChip(
          label: "Semua",
          value: "semua",
          current: filter,
          onTap: onFilterChanged,
        ),
        const SizedBox(width: 8),
        LaporanFilterChip(
          label: "Pemasukan",
          value: "pemasukan",
          current: filter,
          onTap: onFilterChanged,
        ),
        const SizedBox(width: 8),
        LaporanFilterChip(
          label: "Pengeluaran",
          value: "pengeluaran",
          current: filter,
          onTap: onFilterChanged,
        ),
      ],
    );
  }
}

class LaporanFilterChip extends StatelessWidget {
  const LaporanFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;

    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : kBg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : kPrimary,
          ),
        ),
      ),
    );
  }
}