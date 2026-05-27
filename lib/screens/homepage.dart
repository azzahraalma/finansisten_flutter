import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/home/summary_card.dart';
import '../widgets/home/tambah_transaksi_card.dart';
import '../widgets/home/transaksi_list.dart';
import '../widgets/home/bottom_nav.dart';
import 'budget_page.dart';
import 'laporan_page.dart';
import 'profile_page.dart';
import 'notifikasi_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = FirestoreService.instance;
  final auth = AuthService.instance;

  String? userId;
  List<Map<String, dynamic>> transaksiList = [];
  List<Map<String, dynamic>> kategoriList = [];
  List<Map<String, dynamic>> notifikasiList = [];

  bool hasNotification = false;
  double totalPemasukan = 0;
  double totalPengeluaran = 0;

  final amountController = TextEditingController();
  String selectedJenis = 'pemasukan';
  String? selectedKategori;
  DateTime selectedMonth = DateTime.now();
  int currentIndex = 0;

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    userId = auth.getUserId();
    if (userId == null) return;

    final transaksi = await db.getTransaksiByUser(userId!);
    final kategori = await db.getKategoriByUser(userId!);

    List<Map<String, dynamic>> deduped = [];
    for (var item in kategori) {
      final exists = deduped.any((e) =>
          e['nama'].toString().toLowerCase().trim() ==
              item['nama'].toString().toLowerCase().trim() &&
          e['jenis'].toString().toLowerCase().trim() ==
              item['jenis'].toString().toLowerCase().trim());
      if (!exists) deduped.add(item);
    }

    if (deduped.isEmpty) {
      await _insertDefaultKategori();
      final raw = await db.getKategoriByUser(userId!);
      List<Map<String, dynamic>> rawDeduped = [];
      for (var item in raw) {
        final exists = rawDeduped.any((e) =>
            e['nama'].toString().toLowerCase().trim() ==
                item['nama'].toString().toLowerCase().trim() &&
            e['jenis'].toString().toLowerCase().trim() ==
                item['jenis'].toString().toLowerCase().trim());
        if (!exists) rawDeduped.add(item);
      }
      kategoriList = rawDeduped;
    } else {
      kategoriList = deduped;
    }

    final kategoriMasihAda = kategoriList.any((k) =>
        k['nama'].toString() == selectedKategori &&
        k['jenis'].toString() == selectedJenis);
    if (!kategoriMasihAda) selectedKategori = null;

    double masuk = 0, keluar = 0;
    for (var t in transaksi) {
      final date = DateTime.parse(t['tanggal']);
      if (date.month == selectedMonth.month &&
          date.year == selectedMonth.year) {
        if (t['jenis'] == 'pemasukan') {
          masuk += (t['jumlah'] as num).toDouble();
        } else {
          keluar += (t['jumlah'] as num).toDouble();
        }
      }
    }

    setState(() {
      transaksiList = transaksi;
      totalPemasukan = masuk;
      totalPengeluaran = keluar;
    });
  }

  Future<void> _insertDefaultKategori() async {
    final defaults = [
      {'nama': 'Gaji', 'jenis': 'pemasukan'},
      {'nama': 'Belanja', 'jenis': 'pengeluaran'},
      {'nama': 'Kost', 'jenis': 'pengeluaran'},
      {'nama': 'Transportasi', 'jenis': 'pengeluaran'},
      {'nama': 'Makanan', 'jenis': 'pengeluaran'},
    ];
    for (var k in defaults) {
      await db.insertKategori(userId!, k);
    }
  }

  List<Map<String, dynamic>> _getFilteredTransaksi() {
    return transaksiList.where((t) {
      final date = DateTime.parse(t['tanggal']);
      return date.month == selectedMonth.month &&
          date.year == selectedMonth.year;
    }).toList();
  }

  List<Map<String, dynamic>> _getKategoriItems() {
    final filtered = kategoriList
        .where((k) =>
            k['jenis'].toString().toLowerCase().trim() ==
            selectedJenis.toLowerCase().trim())
        .toList();
    final deduped = <Map<String, dynamic>>[];
    for (var item in filtered) {
      final exists = deduped.any((e) =>
          e['nama'].toString().toLowerCase().trim() ==
          item['nama'].toString().toLowerCase().trim());
      if (!exists) deduped.add(item);
    }
    return deduped;
  }

  Future<void> _tambahTransaksi() async {
    if (userId == null) {
      _showTopSnack('User belum login',
          icon: Icons.person_off_outlined, iconColor: Colors.red);
      return;
    }

    final clean = amountController.text.replaceAll('.', '');
    final amount = double.tryParse(clean);
    final namaKategori = selectedKategori ?? '';
    final jenisNormalized = selectedJenis.toLowerCase().trim();

    if (amount == null || amount <= 0 || namaKategori.isEmpty) {
      _showTopSnack('Isi data dengan benar',
          icon: Icons.warning_amber_rounded, iconColor: Colors.orange);
      return;
    }

    String kategoriId;
    final existing = kategoriList.where((k) =>
        k['nama'].toString().toLowerCase().trim() ==
            namaKategori.toLowerCase().trim() &&
        k['jenis'].toString().toLowerCase().trim() == jenisNormalized);

    if (existing.isNotEmpty) {
      kategoriId = existing.first['id'].toString();
    } else {
      kategoriId = await db.insertKategori(
        userId!,
        {'nama': namaKategori, 'jenis': jenisNormalized},
      );
    }

    final transaksiId = await db.insertTransaksi(userId!, {
      'kategori_id': kategoriId,
      'jumlah': amount,
      'jenis': jenisNormalized,
      'tanggal': DateTime.now().toIso8601String(),
    });

    amountController.clear();
    setState(() => selectedKategori = null);
    await _loadData();
    if (!mounted) return;
    _showSuccessPopup(
      icon: Icons.check_circle,
      iconColor: const Color(0xFF6DB5FD),
      message: 'Transaksi Berhasil\nDitambahkan',
    );

    await _addNotifikasi(
      judul: 'Transaksi Berhasil',
      pesan: 'Transaksi berhasil ditambahkan',
      detail: formatRupiah.format(amount),
      tipe: jenisNormalized,
      transaksiId: transaksiId,
    );

    if (jenisNormalized == 'pengeluaran') {
      final warnings = await db.checkBudgetWarning(userId!, transaksiId);
      if (warnings.isNotEmpty && mounted) {
        setState(() => hasNotification = true);
        for (final w in warnings) {
          final pct = (w['percent'] as double).toStringAsFixed(0);
          _showTopSnack('${w['nama']}: budget terpakai $pct%',
              icon: Icons.warning_amber_rounded, iconColor: Colors.orange);
          await Future.delayed(const Duration(milliseconds: 2500));
        }
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.delete_outline,
                      size: 30, color: Colors.red),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hapus Transaksi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012249),
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Yakin mau hapus transaksi ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Batal',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Hapus',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      await db.deleteTransaksi(userId!, id);
      _loadData();
      if (!mounted) return;
      _showSuccessPopup(
        icon: Icons.delete_outline,
        iconColor: Colors.red,
        message: 'Transaksi Berhasil\nDihapus',
      );
    }
  }

  void _editTransaksi(Map<String, dynamic> t) {
    final controller = TextEditingController(
        text: t['jumlah'].toString().replaceAll('.0', ''));
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012249),
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 201, 232, 255),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Rp ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF012249),
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          cursorColor: const Color(0xFF012249),
                          style: const TextStyle(
                            color: Color(0xFF012249),
                            decoration: TextDecoration.none,
                            decorationColor: Colors.transparent,
                          ),
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Masukkan jumlah'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6DB5FD),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final value = double.tryParse(
                              controller.text.replaceAll('.', ''));
                          if (value == null) return;
                          if (userId == null) return;
                          await db.updateTransaksi(
                            userId!,
                            t['id'].toString(),
                            {'jumlah': value},
                          );
                          if (context.mounted) Navigator.pop(context);
                          _loadData();
                        },
                        child: const Text('Simpan',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTambahKategoriDialog() async {
    final ctrl = TextEditingController();
    final hasil = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 201, 232, 255),
                        borderRadius: BorderRadius.circular(22)),
                    child: const Icon(Icons.category_outlined,
                        size: 34, color: Color(0xFF012249)),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Tambah Kategori',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012249),
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'untuk transaksi kamu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.5,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 201, 232, 255),
                        borderRadius: BorderRadius.circular(18)),
                    child: TextField(
                      controller: ctrl,
                      autofocus: true,
                      style: const TextStyle(
                        color: Color(0xFF012249),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Contoh: Hiburan',
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon:
                            Icon(Icons.edit_outlined, color: Color(0xFF012249)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Batal',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, ctrl.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6DB5FD),
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Tambah',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (hasil != null && hasil.isNotEmpty && userId != null) {
      await db.insertKategori(
        userId!,
        {'nama': hasil, 'jenis': selectedJenis},
      );
      await _loadData();
      setState(() => selectedKategori = hasil);
      _showTopSnack('Kategori berhasil ditambahkan',
          icon: Icons.check_circle_outline, iconColor: Colors.green);
    }
  }

  Future<void> _addNotifikasi({
    required String judul,
    required String pesan,
    required String transaksiId,
    String? detail,
    String tipe = 'transaksi',
  }) async {
    if (userId == null) return;
    await db.insertNotification(userId!, {
      'tipe': tipe,
      'judul': judul,
      'pesan': pesan,
      'detail': detail ?? '',
      'waktu': DateTime.now().toIso8601String(),
      'is_read': false,
      'transaksi_id': transaksiId,
    });
    setState(() {
      notifikasiList.insert(0, {
        'judul': judul,
        'pesan': pesan,
        'detail': detail,
        'tipe': tipe,
        'waktu': DateTime.now().toIso8601String(),
        'transaksi_id': transaksiId,
      });
      hasNotification = true;
    });
  }

  void _showTopSnack(
    String text, {
    IconData icon = Icons.info_outline,
    Color iconColor = const Color(0xFF012249),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 250),
            tween: Tween(begin: -20.0, end: 0.0),
            builder: (context, value, child) =>
                Transform.translate(offset: Offset(0, value), child: child),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF012249),
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  void _showSuccessPopup({
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            width: 260,
            padding:
                const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 80, color: iconColor),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF012249),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildTransaksiPage(),
      BudgetPage(key: UniqueKey()),
      const LaporanPage(),
      ProfilePage(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false, 
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Expanded(child: pages[currentIndex]),
            BottomNav(
              currentIndex: currentIndex,
              onTap: (i) async {
                setState(() => currentIndex = i);
                if (i == 0) await _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransaksiPage() {
    return Container(
      color: const Color(0xFF6DB5FD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 44),
                const Text('Transaksi',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF012249))),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotifikasiPage()),
                    ).then((_) => setState(() => hasNotification = false));
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_outlined,
                            color: Color(0xFF012249), size: 22),
                      ),
                      if (hasNotification)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SummaryCard(
                    label: 'Pengeluaran',
                    amount: totalPengeluaran,
                    icon: Icons.arrow_outward,
                    formatRupiah: formatRupiah),
                const SizedBox(width: 12),
                SummaryCard(
                    label: 'Pemasukan',
                    amount: totalPemasukan,
                    icon: Icons.south_west,
                    formatRupiah: formatRupiah),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TambahTransaksiCard(
            amountController: amountController,
            selectedJenis: selectedJenis,
            selectedKategori: selectedKategori,
            kategoriItems: _getKategoriItems(),
            onJenisChanged: (v) => setState(() {
              selectedJenis = v;
              selectedKategori = null;
            }),
            onKategoriChanged: (v) => setState(() => selectedKategori = v),
            onTambah: _tambahTransaksi,
            onTambahKategori: _showTambahKategoriDialog,
          ),
          const SizedBox(height: 12),

          Expanded(
            child: TransaksiList(
              items: _getFilteredTransaksi(),
              formatRupiah: formatRupiah,
              selectedMonth: selectedMonth,
              onEdit: _editTransaksi,
              onDelete: _delete,
              onPickMonth: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => selectedMonth = picked);
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}