import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'laporan_constants.dart';

class LaporanHeader extends StatelessWidget {
  const LaporanHeader({
    super.key,
    required this.monthController,
    required this.onPageChanged,
  });

  final PageController monthController;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Laporan",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: kPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: PageView.builder(
            controller: monthController,
            onPageChanged: onPageChanged,
            itemBuilder: (_, index) {
              final diff = index - 500;
              final month = DateTime(
                DateTime.now().year,
                DateTime.now().month + diff,
              );
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chevron_left, size: 20, color: kPrimary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(month),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 20, color: kPrimary),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}