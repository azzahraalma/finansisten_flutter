import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/local_auth_service.dart';
import 'package:finansisten/widgets/laporan/laporan_constants.dart';
import 'package:finansisten/widgets/laporan/laporan_header.dart';
import 'package:finansisten/widgets/laporan/laporan_chart_card.dart';
import 'package:finansisten/widgets/laporan/laporan_summary.dart';
import 'package:finansisten/widgets/laporan/laporan_filter.dart';
import 'package:finansisten/widgets/laporan/laporan_transaksi.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final _auth = LocalAuthService();

  DateTime selectedMonth = DateTime.now();

  List<Map<String, dynamic>> transaksi = [];
  Map<String, dynamic> summary = {};
  Map<String, dynamic> previousSummary = {};

  String filter = 'semua';
  String tips = '';

  bool loading = true;
  bool tipsVisible = false;
  int touchedIndex = -1;

  late PageController monthController;

  @override
  void initState() {
    super.initState();
    monthController = PageController(initialPage: 500);
    _loadLaporan();
  }

  @override
  void dispose() {
    monthController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────

  Future<void> _loadLaporan() async {
    setState(() => loading = true);

    final userId = await _auth.getUserId();
    if (userId == null) {
      setState(() => loading = false);
      return;
    }

    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final prevStart = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    final prevEnd = DateTime(selectedMonth.year, selectedMonth.month, 0);

    final data = await DatabaseHelper.instance.getLaporanByPeriode(
      userId,
      start.toIso8601String(),
      end.toIso8601String(),
    );

    final current = await DatabaseHelper.instance.getSummaryLaporan(
      userId,
      start.toIso8601String(),
      end.toIso8601String(),
    );

    final previous = await DatabaseHelper.instance.getSummaryLaporan(
      userId,
      prevStart.toIso8601String(),
      prevEnd.toIso8601String(),
    );

    _generateTips(current, previous);

    setState(() {
      transaksi = data;
      summary = current;
      previousSummary = previous;
      loading = false;
    });
  }

  void _generateTips(Map current, Map previous) {
    final now = (current['total_pengeluaran'] ?? 0).toDouble();
    final before = (previous['total_pengeluaran'] ?? 0).toDouble();

    if (before == 0 && now > 0) {
      tips = "Ini bulan pertamamu tercatat. Yuk mulai konsisten 🚀";
      return;
    }

    if (now < before) {
      tips =
          "Hebat! Kamu lebih hemat ${formatRupiah(before - now)} dari bulan lalu 🎉\n"
          "Kalau konsisten, selisih ini bisa kamu alihkan ke tabungan atau dana darurat.";
    } else if (now > before) {
      tips =
          "Pengeluaranmu naik ${formatRupiah(_selisihPengeluaran)} dibanding bulan lalu 👀\n"
          "Coba cek kategori pengeluaran terbesar di diagram, lalu tentukan satu pos yang bisa dikurangi minggu depan.";
    } else {
      tips =
          "Pengeluaranmu stabil dibanding bulan lalu 👍\n"
          "Sekarang coba tantang diri untuk mengurangi minimal 5% bulan depan agar target tabungan lebih cepat tercapai.";
    }
  }

  // ── Computed ──────────────────────────

  List<Map<String, dynamic>> get _filtered {
    if (filter == 'semua') return transaksi;
    return transaksi.where((e) => e['jenis'] == filter).toList();
  }

  Map<String, double> get _categoryData {
    final map = <String, double>{};
    for (var t in transaksi) {
      if (t['jenis'] == 'pengeluaran') {
        map[t['kategori_nama']] =
            (map[t['kategori_nama']] ?? 0) + t['jumlah'].toDouble();
      }
    }
    return map;
  }

  double get _selisihPengeluaran {
    final now = (summary['total_pengeluaran'] ?? 0).toDouble();
    final before = (previousSummary['total_pengeluaran'] ?? 0).toDouble();
    return now - before;
  }

  // ── Build ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pemasukan = (summary['total_pemasukan'] ?? 0).toDouble();
    final pengeluaran = (summary['total_pengeluaran'] ?? 0).toDouble();
    final sisa = pemasukan - pengeluaran;
    final prevPengeluaran =
        (previousSummary['total_pengeluaran'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: kAccent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            LaporanHeader(
              monthController: monthController,
              onPageChanged: (index) {
                final diff = index - 500;
                setState(() {
                  selectedMonth = DateTime(
                    DateTime.now().year,
                    DateTime.now().month + diff,
                  );
                });
                _loadLaporan();
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: kAccent),
                      )
                    : GestureDetector(
                        onTap: () {
                          if (tipsVisible) {
                            setState(() => tipsVisible = false);
                          }
                        },
                        behavior: HitTestBehavior.translucent,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LaporanChartCard(
                                tips: tips,
                                tipsVisible: tipsVisible,
                                touchedIndex: touchedIndex,
                                categoryData: _categoryData,
                                selisih: _selisihPengeluaran,
                                prevPengeluaran: prevPengeluaran,
                                onTipsToggle: () => setState(
                                    () => tipsVisible = !tipsVisible),
                                onTouched: (i) =>
                                    setState(() => touchedIndex = i),
                              ),
                              const SizedBox(height: 16),
                              LaporanSummaryRow(
                                pemasukan: pemasukan,
                                pengeluaran: pengeluaran,
                                sisa: sisa,
                              ),
                              const SizedBox(height: 16),
                              LaporanFilterRow(
                                filter: filter,
                                onFilterChanged: (val) =>
                                    setState(() => filter = val),
                              ),
                              const SizedBox(height: 16),
                              LaporanTransaksiList(filtered: _filtered),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}