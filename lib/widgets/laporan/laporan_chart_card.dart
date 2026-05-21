import 'package:flutter/material.dart';
import 'laporan_constants.dart';
import 'laporan_tips.dart';
import 'laporan_pie_chart.dart';
import 'laporan_indikator.dart';

class LaporanChartCard extends StatelessWidget {
  const LaporanChartCard({
    super.key,
    required this.tips,
    required this.tipsVisible,
    required this.touchedIndex,
    required this.categoryData,
    required this.selisih,
    required this.prevPengeluaran,
    required this.onTipsToggle,
    required this.onTouched,
  });

  final String tips;
  final bool tipsVisible;
  final int touchedIndex;
  final Map<String, double> categoryData;
  final double selisih;
  final double prevPengeluaran;
  final VoidCallback onTipsToggle;
  final ValueChanged<int> onTouched;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tips.isNotEmpty)
                TipsButton(onTap: onTipsToggle),
              LaporanPieChart(
                categoryData: categoryData,
                touchedIndex: touchedIndex,
                onTouched: onTouched,
              ),
              const SizedBox(height: 22),
              LaporanPieChartLegend(categoryData: categoryData),
              if (prevPengeluaran > 0) ...[
                const SizedBox(height: 14),
                IndikatorBulanLalu(selisih: selisih),
              ],
            ],
          ),
        ),
        if (tipsVisible)
          Positioned(
            top: 44,
            left: 16,
            right: 16,
            child: TipsPopup(tips: tips, visible: tipsVisible),
          ),
      ],
    );
  }
}