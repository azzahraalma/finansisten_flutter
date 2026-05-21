import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'laporan_constants.dart';

class LaporanTransaksiList extends StatelessWidget {
  const LaporanTransaksiList({super.key, required this.filtered});

  final List<Map<String, dynamic>> filtered;

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            "Belum ada transaksi",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: filtered
          .map((t) => LaporanTransaksiTile(transaksi: t))
          .toList(),
    );
  }
}

class LaporanTransaksiTile extends StatelessWidget {
  const LaporanTransaksiTile({super.key, required this.transaksi});

  final Map<String, dynamic> transaksi;

  @override
  Widget build(BuildContext context) {
    final isPemasukan = transaksi['jenis'] == 'pemasukan';
    final date = DateTime.parse(transaksi['tanggal']);
    final timeStr = DateFormat('HH:mm - MMM d', 'id_ID').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPemasukan ? kAccent : kPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              getKategoriIcon(transaksi['kategori_nama'] ?? ''),
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
                    color: kPrimary,
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 11, color: kAccent),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: Colors.grey.shade200,
          ),
          Text(
            "${isPemasukan ? '' : '-'}${formatRupiah(transaksi['jumlah'])}",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}