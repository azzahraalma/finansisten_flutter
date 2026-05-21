import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetCard extends StatelessWidget {
  final Map<String, dynamic> budget;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _iconForKategori(String nama) {
    switch (nama.toLowerCase()) {
      case 'makanan': return Icons.restaurant_outlined;
      case 'transportasi': return Icons.directions_bus_outlined;
      case 'belanja': return Icons.shopping_bag_outlined;
      case 'kost': return Icons.home_outlined;
      case 'hiburan': return Icons.confirmation_number_outlined;
      default: return Icons.wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final limit = (budget['limit_amount'] as num).toDouble();
    final spent = (budget['total_spent'] as num).toDouble();
    final percent = (spent / limit * 100).clamp(0.0, 100.0);
    final isWarning = percent >= 40;
    final nama = budget['kategori_nama'] as String? ?? '-';
    final sisa = limit - spent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon ──
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF012249),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconForKategori(nama), color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),

          // ── Konten ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF012249),
                  ),
                ),
                const SizedBox(height: 6),

                // Progress bar
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: LinearProgressIndicator(
                        minHeight: 22,
                        value: percent / 100,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percent >= 80 ? Colors.orange : const Color(0xFF012249),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        currency.format(sisa),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: percent >= 50
                              ? Colors.white
                              : const Color(0xFF4A90D9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Persen + status
                Row(
                  children: [
                    Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF012249),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isWarning)
                      const Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 13),
                        SizedBox(width: 3),
                        Text('Peringatan',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ])
                    else
                      const Row(children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 13),
                        SizedBox(width: 3),
                        Text('Aman',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Aksi ──
          Row(
            children: [
              _actionBtn(
                icon: Icons.edit_outlined,
                color: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF012249),
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _actionBtn(
                icon: Icons.delete_outline,
                color: const Color(0xFFFFEBEB),
                iconColor: Colors.red,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}