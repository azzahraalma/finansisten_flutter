import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaksi_tile.dart';

class TransaksiList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final NumberFormat formatRupiah;
  final DateTime selectedMonth;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;
  final VoidCallback onPickMonth;

  const TransaksiList({
    super.key,
    required this.items,
    required this.formatRupiah,
    required this.selectedMonth,
    required this.onEdit,
    required this.onDelete,
    required this.onPickMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bulan Ini',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF012249),
                  ),
                ),
                GestureDetector(
                  onTap: onPickMonth,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF012249),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada transaksi bulan ini',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    itemCount: items.length,
                    itemBuilder: (context, index) => TransaksiTile(
                      transaksi: items[index],
                      formatRupiah: formatRupiah,
                      onEdit: () => onEdit(items[index]),
                      onDelete: () => onDelete(items[index]['id'].toString()),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}