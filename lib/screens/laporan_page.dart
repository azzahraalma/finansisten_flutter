import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../services/local_auth_service.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final auth = LocalAuthService();

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

  final List<Color> chartColors = const [
    Color(0xFF012249),
    Color(0xFF6DB5FD),
    Color(0xFF4A90D9),
    Color(0xFF90CAF9),
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
    Color(0xFF0D47A1),
  ];

  @override
  void initState() {
    super.initState();
    monthController = PageController(initialPage: 500);
    loadLaporan();
  }

  @override
  void dispose() {
    monthController.dispose();
    super.dispose();
  }

  String format(num n) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(n);
  }

  Future<void> loadLaporan() async {
    setState(() => loading = true);

    final userId = await auth.getUserId() ?? 1;

    final start =
        DateTime(selectedMonth.year, selectedMonth.month, 1);

    final end =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    final prevStart =
        DateTime(selectedMonth.year, selectedMonth.month - 1, 1);

    final prevEnd =
        DateTime(selectedMonth.year, selectedMonth.month, 0);

    final data =
        await DatabaseHelper.instance.getLaporanByPeriode(
      userId,
      start.toIso8601String(),
      end.toIso8601String(),
    );

    final current =
        await DatabaseHelper.instance.getSummaryLaporan(
      userId,
      start.toIso8601String(),
      end.toIso8601String(),
    );

    final previous =
        await DatabaseHelper.instance.getSummaryLaporan(
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

  void _generateTips(
    Map current,
    Map previous,
  ) {
    final now =
        (current['total_pengeluaran'] ?? 0).toDouble();

    final before =
        (previous['total_pengeluaran'] ?? 0).toDouble();

    if (before == 0 && now > 0) {
      tips =
          "Ini bulan pertamamu tercatat. Yuk mulai konsisten 🚀";
      return;
    }

    if (now < before) {
      tips =
          "Hebat! Kamu lebih hemat ${format(before - now)} dari bulan lalu 🎉\nKalau konsisten, selisih ini bisa kamu alihkan ke tabungan atau dana darurat.";
    } else if (now > before) {
      tips =
          "Pengeluaranmu naik ${format(_selisihPengeluaran)} dibanding bulan lalu 👀\nCoba cek kategori pengeluaran terbesar di diagram, lalu tentukan satu pos yang bisa dikurangi minggu depan.";
    } else {
      tips =
          "Pengeluaranmu stabil dibanding bulan lalu 👍\nSekarang coba tantang diri untuk mengurangi minimal 5% bulan depan agar target tabungan lebih cepat tercapai.";
    }
  }

  List<Map<String, dynamic>> get filtered {
    if (filter == 'semua') return transaksi;

    return transaksi
        .where((e) => e['jenis'] == filter)
        .toList();
  }

  Map<String, double> get categoryData {
    final map = <String, double>{};

    for (var t in transaksi) {
      if (t['jenis'] == 'pengeluaran') {
        map[t['kategori_nama']] =
            (map[t['kategori_nama']] ?? 0) +
                t['jumlah'].toDouble();
      }
    }

    return map;
  }

  double get _selisihPengeluaran {
    final now =
        (summary['total_pengeluaran'] ?? 0).toDouble();

    final before =
        (previousSummary['total_pengeluaran'] ?? 0)
            .toDouble();

    return now - before;
  }

  Widget _buildPieChart() {
    final entries =
        categoryData.entries.toList();

    if (entries.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 52,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              Text(
                "Belum ada data pengeluaran",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total =
        categoryData.values.reduce(
      (a, b) => a + b,
    );

    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData:
                  PieTouchData(
                touchCallback:
                    (event, response) {
                  setState(() {
                    touchedIndex =
                        response
                                ?.touchedSection
                                ?.touchedSectionIndex ??
                            -1;
                  });
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 68,
              sections: List.generate(
                entries.length,
                (i) {
                  final touched =
                      i == touchedIndex;

                  return PieChartSectionData(
                    color: chartColors[
                        i %
                            chartColors
                                .length],
                    value:
                        entries[i].value,
                    radius:
                        touched
                            ? 76
                            : 62,
                    title:
                        "${((entries[i].value / total) * 100).toStringAsFixed(0)}%",
                    titleStyle:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                "Total:",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                format(total),
                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF012249),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final entries =
        categoryData.entries.toList();

    if (entries.isEmpty) {
      return const SizedBox();
    }

    return Center(
      child: Wrap(
        alignment:
            WrapAlignment.center,
        crossAxisAlignment:
            WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 10,
        children:
            List.generate(entries.length, (i) {
          return Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(
                  color: chartColors[
                      i %
                          chartColors
                              .length],
                  shape:
                      BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                entries[i].key,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      Color(0xFF012249),
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  IconData _getIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'gaji':
        return Icons
            .monetization_on_outlined;

      case 'belanja':
        return Icons
            .shopping_bag_outlined;

      case 'kost':
        return Icons.home_outlined;

      case 'transportasi':
        return Icons
            .directions_bus_outlined;

      case 'makanan':
        return Icons
            .restaurant_outlined;

      default:
        return Icons
            .category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pemasukan =
        (summary['total_pemasukan'] ?? 0)
            .toDouble();

    final pengeluaran =
        (summary['total_pengeluaran'] ??
                0)
            .toDouble();

    final sisa =
        pemasukan - pengeluaran;

    final selisih =
        _selisihPengeluaran;

    final prevPengeluaran =
        (previousSummary[
                    'total_pengeluaran'] ??
                0)
            .toDouble();

    return Scaffold(
      backgroundColor:
          const Color(0xFF6DB5FD),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                14,
                20,
                6,
              ),
              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Text(
                    "Laporan",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.w900,
                      color: Color(
                          0xFF012249),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 40,
              child:
                  PageView.builder(
                controller:
                    monthController,
                onPageChanged:
                    (index) {
                  final diff =
                      index - 500;

                  setState(() {
                    selectedMonth =
                        DateTime(
                      DateTime.now()
                          .year,
                      DateTime.now()
                              .month +
                          diff,
                    );
                  });

                  loadLaporan();
                },
                itemBuilder:
                    (_, index) {
                  final diff =
                      index - 500;

                  final month =
                      DateTime(
                    DateTime.now()
                        .year,
                    DateTime.now()
                            .month +
                        diff,
                  );

                  return Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const Icon(
                        Icons
                            .chevron_left,
                        size: 20,
                        color: Color(
                            0xFF012249),
                      ),
                      const SizedBox(
                          width: 8),
                      Text(
                        DateFormat(
                          'MMMM yyyy',
                          'id_ID',
                        ).format(
                          month,
                        ),
                        style:
                            const TextStyle(
                          fontSize:
                              16,
                          fontWeight:
                              FontWeight
                                  .w600,
                          color: Color(
                              0xFF012249),
                        ),
                      ),
                      const SizedBox(
                          width: 8),
                      const Icon(
                        Icons
                            .chevron_right,
                        size: 20,
                        color: Color(
                            0xFF012249),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(
                height: 20),

            Expanded(
              child: Container(
                width:
                    double.infinity,
                clipBehavior:
                    Clip.antiAlias,
                decoration:
                    const BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        Radius.circular(
                            30),
                    topRight:
                        Radius.circular(
                            30),
                  ),
                ),
                child: loading
                    ? const Center(
                        child:
                            CircularProgressIndicator(
                          color: Color(
                              0xFF6DB5FD),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          if (tipsVisible) {
                            setState(() {
                              tipsVisible =
                                  false;
                            });
                          }
                        },
                        behavior:
                            HitTestBehavior
                                .translucent,
                        child:
                            SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            28,
                            16,
                            40,
                          ),
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width:
                                        double.infinity,
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      20,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          const Color(
                                              0xFFDEEEFF),
                                      borderRadius:
                                          BorderRadius.circular(
                                              28),
                                    ),
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        if (tips
                                            .isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              setState(
                                                () {
                                                  tipsVisible =
                                                      !tipsVisible;
                                                },
                                              );
                                            },
                                            child:
                                                const Padding(
                                              padding:
                                                  EdgeInsets.only(
                                                top:
                                                    6,
                                                bottom:
                                                    18,
                                              ),
                                              child:
                                                  Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.lightbulb_outline,
                                                    size:
                                                        16,
                                                    color:
                                                        Color(0xFF012249),
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          6),
                                                  Text(
                                                    "Tips Keuangan",
                                                    style:
                                                        TextStyle(
                                                      fontSize:
                                                          13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Color(0xFF012249),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                        _buildPieChart(),

                                        const SizedBox(
                                            height:
                                                22),

                                        _buildLegend(),

                                        if (prevPengeluaran >
                                            0) ...[
                                          const SizedBox(
                                              height:
                                                  14),
                                          _indikatorBulanLalu(
                                            selisih,
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),

                                  if (tipsVisible)
                                    Positioned(
                                      top:
                                          44,
                                      left:
                                          16,
                                      right:
                                          16,
                                      child:
                                          AnimatedOpacity(
                                        duration:
                                            const Duration(
                                          milliseconds:
                                              200,
                                        ),
                                        opacity:
                                            tipsVisible
                                                ? 1
                                                : 0,
                                        child:
                                            Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal:
                                                16,
                                            vertical:
                                                14,
                                          ),
                                          decoration:
                                              BoxDecoration(
                                            color:
                                                Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                        0xFF012249)
                                                    .withOpacity(
                                                        0.15),
                                                blurRadius:
                                                    20,
                                                offset:
                                                    const Offset(
                                                  0,
                                                  6,
                                                ),
                                              )
                                            ],
                                          ),
                                          child:
                                              Row(
                                            children: [
                                              const Icon(
                                                Icons.auto_awesome,
                                                size:
                                                    16,
                                                color:
                                                    Color(0xFF6DB5FD),
                                              ),
                                              const SizedBox(
                                                  width:
                                                      10),
                                              Expanded(
                                                child:
                                                    Text(
                                                  tips,
                                                  style:
                                                      const TextStyle(
                                                    fontSize:
                                                        13,
                                                    color:
                                                        Color(0xFF012249),
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    height:
                                                        1.4,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                ],
                              ),

                              const SizedBox(
                                  height:
                                      16),

                              Row(
                                children: [
                                  _summaryCard(
                                    "Pengeluaran",
                                    pengeluaran,
                                    Icons
                                        .arrow_outward,
                                    const Color(
                                        0xFF012249),
                                  ),
                                  const SizedBox(
                                      width:
                                          8),
                                  _summaryCard(
                                    "Pemasukan",
                                    pemasukan,
                                    Icons
                                        .south_west,
                                    const Color(
                                        0xFF6DB5FD),
                                  ),
                                  const SizedBox(
                                      width:
                                          8),
                                  _sisaCard(
                                      sisa),
                                ],
                              ),

                              const SizedBox(
                                  height:
                                      16),

                              Row(
                                children: [
                                  _filterChip(
                                    "Semua",
                                    "semua",
                                  ),
                                  const SizedBox(
                                      width:
                                          8),
                                  _filterChip(
                                    "Pemasukan",
                                    "pemasukan",
                                  ),
                                  const SizedBox(
                                      width:
                                          8),
                                  _filterChip(
                                    "Pengeluaran",
                                    "pengeluaran",
                                  ),
                                ],
                              ),

                              const SizedBox(
                                  height:
                                      16),

                              if (filtered
                                  .isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    vertical:
                                        30,
                                  ),
                                  child:
                                      Center(
                                    child:
                                        Text(
                                      "Belum ada transaksi",
                                      style:
                                          TextStyle(
                                        color: Colors
                                            .grey
                                            .shade400,
                                        fontSize:
                                            13,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...filtered.map(
                                  (t) =>
                                      _transaksiTile(
                                          t),
                                )
                            ],
                          ),
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    String label,
    String value,
  ) {
    final isSelected =
        filter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          filter = value;
        });
      },
      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration:
            BoxDecoration(
          color: isSelected
              ? const Color(
                  0xFF012249)
              : const Color(
                  0xFFF0F7FF),
          borderRadius:
              BorderRadius.circular(
                  30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color: isSelected
                ? Colors.white
                : const Color(
                    0xFF012249),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFFF0F7FF),
          borderRadius:
              BorderRadius.circular(
                  16),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .center,
          children: [
            Container(
              padding:
                  const EdgeInsets.all(
                      6),
              decoration:
                  BoxDecoration(
                border: Border.all(
                  color: color,
                  width: 1.5,
                ),
                borderRadius:
                    BorderRadius.circular(
                        8),
              ),
              child: Icon(
                icon,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(
                height: 8),
            Text(
              label,
              style:
                  const TextStyle(
                fontSize: 14,
                fontWeight:FontWeight.bold ,
                color:
                    Color(0xFF012249),
              ),
            ),
            const SizedBox(
                height: 2),
            Text(
              format(amount),
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 14,
                color: Color(
                    0xFF012249),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sisaCard(
    double sisa,
  ) {
    final isPositive =
        sisa >= 0;

    final color =
        isPositive
            ? const Color(
                0xFF1565C0)
            : Colors
                .red.shade400;

    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFFF0F7FF),
          borderRadius:
              BorderRadius.circular(
                  16),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .center,
          children: [
            Container(
              padding:
                  const EdgeInsets.all(
                      6),
              decoration:
                  BoxDecoration(
                border: Border.all(
                  color: color,
                  width: 1.5,
                ),
                borderRadius:
                    BorderRadius.circular(
                        8),
              ),
              child: Icon(
                isPositive
                    ? Icons
                        .savings_outlined
                    : Icons
                        .warning_amber_outlined,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(
                height: 8),
            const Text(
              "Saldo",
              style:
                  TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color: Color(
                    0xFF1565C0),
              ),
            ),
            const SizedBox(
                height: 2),
            Text(
              format(
                sisa.abs(),
              ),
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _indikatorBulanLalu(
      double selisih) {
    final isHemat =
        selisih <= 0;

    final color =
        isHemat
            ? const Color(
                0xFF1565C0)
            : Colors
                .red.shade400;

    final icon =
        isHemat
            ? Icons
                .trending_down
            : Icons.trending_up;

    final label =
        isHemat
            ? "Hemat ${format(selisih.abs())} dari bulan lalu"
            : "Lebih boros ${format(selisih.abs())} dari bulan lalu";

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(
                0.08),
        borderRadius:
            BorderRadius.circular(
                12),
        border: Border.all(
          color:
              color.withOpacity(
                  0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(
              width: 8),
          Expanded(
            child: Text(
              label,
              style:
                  TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transaksiTile(
      Map<String, dynamic> t) {
    final isPemasukan =
        t['jenis'] ==
            'pemasukan';

    final date =
        DateTime.parse(
            t['tanggal']);

    final timeStr =
        DateFormat(
      'HH:mm - MMM d',
      'id_ID',
    ).format(date);

    return Padding(
      padding:
          const EdgeInsets.only(
              bottom: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color: isPemasukan
                  ? const Color(
                      0xFF6DB5FD)
                  : const Color(
                      0xFF012249),
              shape:
                  BoxShape.circle,
            ),
            child: Icon(
              _getIcon(
                t['kategori_nama'] ??
                    '',
              ),
              color:
                  Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(
              width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  t['kategori_nama'] ??
                      '-',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .w600,
                    fontSize:
                        14,
                    color: Color(
                        0xFF012249),
                  ),
                ),
                Text(
                  timeStr,
                  style:
                      const TextStyle(
                    fontSize:
                        11,
                    color: Color(
                        0xFF6DB5FD),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 32,
            margin:
                const EdgeInsets.symmetric(
                    horizontal:
                        10),
            color: Colors
                .grey
                .shade200,
          ),
          Text(
            "${isPemasukan ? '' : '-'}${format(t['jumlah'])}",
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
              fontSize: 14,
              color: Color(
                  0xFF012249),
            ),
          )
        ],
      ),
    );
  }
}