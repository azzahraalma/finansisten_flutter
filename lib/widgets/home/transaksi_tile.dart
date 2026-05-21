import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransaksiTile extends StatelessWidget {
  final Map<String, dynamic> transaksi;
  final NumberFormat formatRupiah;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransaksiTile({
    super.key,
    required this.transaksi,
    required this.formatRupiah,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'gaji': return Icons.monetization_on_outlined;
      case 'belanja': return Icons.shopping_bag_outlined;
      case 'kost': return Icons.home_outlined;
      case 'transportasi': return Icons.directions_bus_outlined;
      case 'makanan': return Icons.restaurant_outlined;
      default: return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPemasukan = transaksi['jenis'] == 'pemasukan';
    final date = DateTime.parse(transaksi['tanggal']);
    final timeStr = DateFormat('HH:mm - MMM d').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPemasukan ? const Color(0xFF6DB5FD) : const Color(0xFF012249),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(transaksi['kategori_nama'] ?? ''),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaksi['kategori_nama'] ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF012249),
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6DB5FD)),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Text(
            "${isPemasukan ? '' : '-'}${formatRupiah.format(transaksi['jumlah'])}",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF012249),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onEdit,
            child: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}