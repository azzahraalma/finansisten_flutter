import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'laporan_constants.dart';

class LaporanPieChart extends StatelessWidget {
  const LaporanPieChart({
    super.key,
    required this.categoryData,
    required this.touchedIndex,
    required this.onTouched,
  });

  final Map<String, double> categoryData;
  final int touchedIndex;
  final ValueChanged<int> onTouched;

  @override
  Widget build(BuildContext context) {
    final entries = categoryData.entries.toList();

    if (entries.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 52, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                "Belum ada data pengeluaran",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final total = categoryData.values.reduce((a, b) => a + b);

    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  onTouched(
                    response?.touchedSection?.touchedSectionIndex ?? -1,
                  );
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 68,
              sections: List.generate(entries.length, (i) {
                final touched = i == touchedIndex;
                return PieChartSectionData(
                  color: kChartColors[i % kChartColors.length],
                  value: entries[i].value,
                  radius: touched ? 76 : 62,
                  title:
                      "${((entries[i].value / total) * 100).toStringAsFixed(0)}%",
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Total:",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                formatRupiah(total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LaporanPieChartLegend extends StatelessWidget {
  const LaporanPieChartLegend({super.key, required this.categoryData});

  final Map<String, double> categoryData;

  @override
  Widget build(BuildContext context) {
    final entries = categoryData.entries.toList();

    if (entries.isEmpty) return const SizedBox();

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 10,
        children: List.generate(entries.length, (i) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: kChartColors[i % kChartColors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                entries[i].key,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: kPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}