import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const kPrimary = Color(0xFF012249);
const kAccent = Color(0xFF6DB5FD);
const kBg = Color(0xFFF0F7FF);
const kCardBg = Color(0xFFDEEEFF);

const List<Color> kChartColors = [
  Color(0xFF012249),
  Color(0xFF6DB5FD),
  Color(0xFF4A90D9),
  Color(0xFF90CAF9),
  Color(0xFF1565C0),
  Color(0xFF42A5F5),
  Color(0xFF0D47A1),
];

String formatRupiah(num n) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(n);
}

IconData getKategoriIcon(String kategori) {
  switch (kategori.toLowerCase()) {
    case 'gaji':
      return Icons.monetization_on_outlined;
    case 'belanja':
      return Icons.shopping_bag_outlined;
    case 'kost':
      return Icons.home_outlined;
    case 'transportasi':
      return Icons.directions_bus_outlined;
    case 'makanan':
      return Icons.restaurant_outlined;
    default:
      return Icons.category_outlined;
  }
}