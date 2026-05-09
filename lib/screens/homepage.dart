import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/local_auth_service.dart';
import 'package:intl/intl.dart';
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
  final db = DatabaseHelper.instance;
  final auth = LocalAuthService();

  int? userId;

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
    _loadKategori();
  }

  Future<void> _loadData() async {
    userId = await auth.getUserId();
    if (userId == null) return;

    final transaksi = await db.getTransaksiByUser(userId!);
    final kategori = await db.getKategoriByUser(userId!);

    final normalized = kategori
        .map((e) => {...e, 'id': (e['id'] as num).toInt()})
        .toList();

    List<Map<String, dynamic>> deduped = [];
    for (var item in normalized) {
      final exists = deduped.any(
        (e) =>
            e['nama'].toString().toLowerCase().trim() ==
                item['nama'].toString().toLowerCase().trim() &&
            e['jenis'].toString().toLowerCase().trim() ==
                item['jenis'].toString().toLowerCase().trim(),
      );
      if (!exists) deduped.add(item);
    }

    if (deduped.isEmpty) {
      await _insertDefaultKategori();
      final raw = await db.getKategoriByUser(userId!);
      final rawNormalized =
          raw.map((e) => {...e, 'id': (e['id'] as num).toInt()}).toList();
      List<Map<String, dynamic>> rawDeduped = [];
      for (var item in rawNormalized) {
        final exists = rawDeduped.any(
          (e) =>
              e['nama'].toString().toLowerCase().trim() ==
                  item['nama'].toString().toLowerCase().trim() &&
              e['jenis'].toString().toLowerCase().trim() ==
                  item['jenis'].toString().toLowerCase().trim(),
        );
        if (!exists) rawDeduped.add(item);
      }
      kategoriList = rawDeduped;
    } else {
      kategoriList = deduped;
    }

    final kategoriMasihAda = kategoriList.any(
      (k) =>
          k['nama'].toString() == selectedKategori &&
          k['jenis'].toString() == selectedJenis,
    );
    if (!kategoriMasihAda) selectedKategori = null;

    double masuk = 0;
    double keluar = 0;
    for (var t in transaksi) {
      final date = DateTime.parse(t['tanggal']);
      if (date.month == selectedMonth.month &&
          date.year == selectedMonth.year) {
        if (t['jenis'] == 'pemasukan') {
          masuk += t['jumlah'];
        } else {
          keluar += t['jumlah'];
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
      await db.insertKategori({...k, 'user_id': userId});
    }
  }

  Future<void> _loadKategori() async {
    final uid = await auth.getUserId();
    if (uid == null) return;
    final data = await db.getKategoriByUser(uid);
    setState(() => kategoriList = data);
  }

  void _showTopSnack(
    String text, {
    IconData icon = Icons.info_outline,
    Color iconColor = const Color(0xFF012249),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
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
                    offset: const Offset(0, 4),
                  ),
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
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, size: 80, color: Color(0xFF6DB5FD)),
              SizedBox(height: 16),
              Text(
                "Transaksi Berhasil\nDitambahkan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  decoration: TextDecoration.none,
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
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // FIX: tambahkan parameter transaksiId supaya notif ikut
  //      terhapus ketika transaksinya dihapus
  // ─────────────────────────────────────────────────────────────
  Future<void> _addNotifikasi({
    required String judul,
    required String pesan,
    required int transaksiId, // ← wajib sekarang
    String? detail,
    String tipe = 'transaksi',
  }) async {
    await db.insertNotification({
      'tipe': tipe,
      'judul': judul,
      'pesan': pesan,
      'detail': detail ?? '',
      'waktu': DateTime.now().toIso8601String(),
      'is_read': 0,
      'transaksi_id': transaksiId, // ← disimpan ke DB
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

    int kategoriId;
    final existing = kategoriList
        .where((k) =>
            k['nama'].toString().toLowerCase().trim() ==
                namaKategori.toLowerCase().trim() &&
            k['jenis'].toString().toLowerCase().trim() == jenisNormalized)
        .toList();

    if (existing.isNotEmpty) {
      kategoriId = (existing.first['id'] as num).toInt();
    } else {
      kategoriId = await db.insertKategori({
        'user_id': userId!,
        'nama': namaKategori,
        'jenis': jenisNormalized,
      });
    }

    final transaksiId = await db.insertTransaksi({
      'user_id': userId!,
      'kategori_id': kategoriId,
      'jumlah': amount,
      'jenis': jenisNormalized,
      'tanggal': DateTime.now().toIso8601String(),
    });

    amountController.clear();
    setState(() => selectedKategori = null);
    await _loadData();
    if (!mounted) return;
    _showSuccessPopup();

    // ─── FIX: pass transaksiId ke _addNotifikasi ───
    await _addNotifikasi(
      judul: 'Transaksi Berhasil',
      pesan: 'Transaksi berhasil ditambahkan',
      detail: formatRupiah.format(amount),
      tipe: jenisNormalized,
      transaksiId: transaksiId, // ← ini kuncinya
    );

    // Cek budget warning setelah transaksi pengeluaran
    if (jenisNormalized == 'pengeluaran' && userId != null) {
      final warnings = await db.checkBudgetWarning(userId!, transaksiId);
      if (warnings.isNotEmpty && mounted) {
        setState(() => hasNotification = true);
        for (final w in warnings) {
          final pct = (w['percent'] as double).toStringAsFixed(0);
          _showTopSnack(
            '${w['nama']}: budget terpakai $pct%',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
          );
          await Future.delayed(const Duration(milliseconds: 2500));
        }
      }
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 28,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            28,
            24,
            24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
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
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 30,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Hapus Transaksi",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012249),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Yakin mau hapus transaksi ini?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(
                            context,
                            false,
                          ),
                      style:
                          OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          50,
                        ),
                        side: BorderSide(
                          color:
                              Colors.grey.shade300,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  16),
                        ),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(
                            context,
                            true,
                          ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red,
                        elevation: 0,
                        minimumSize:
                            const Size(
                          double.infinity,
                          50,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  16),
                        ),
                      ),
                      child: const Text(
                        "Hapus",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await db.deleteTransaksi(
        id,
        userId: userId,
      );

      _showTopSnack(
        'Transaksi berhasil dihapus',
        icon: Icons.delete_outline,
        iconColor: Colors.red,
      );

      _loadData();
    }
  }
  void _editTransaksi(Map<String, dynamic> t) {
    final controller = TextEditingController(
        text: t['jumlah'].toString().replaceAll('.0', ''));
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Edit Transaksi",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF012249)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 201, 232, 255),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text("Rp ",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF012249))),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      cursorColor: const Color(0xFF012249),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Masukkan jumlah"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
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
                  child: const Text("Batal"),
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
                    await db.updateTransaksi({'id': t['id'], 'jumlah': value});
                    Navigator.pop(context);
                    _loadData();
                  },
                  child: const Text("Simpan",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String kategori) {
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

  Widget _buildTransaksiPage() {
    final allItems = _getFilteredTransaksi();
    final kategoriItems = _getKategoriItems();
    final validSelectedKategori = kategoriItems.any(
            (k) => k['nama'].toString() == selectedKategori)
        ? selectedKategori
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF6DB5FD),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 44),
                  const Text(
                    "Transaksi",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012249),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotifikasiPage()),
                      ).then((_) =>
                          setState(() => hasNotification = false));
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
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
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Summary Cards ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _summaryCard("Pengeluaran", totalPengeluaran,
                      Icons.arrow_outward),
                  const SizedBox(width: 12),
                  _summaryCard(
                      "Pemasukan", totalPemasukan, Icons.south_west),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Tambah Transaksi card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tambah Transaksi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF012249),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          flex: 4,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 201, 232, 255),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Text("Rp ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF012249))),
                                Expanded(
                                  child: TextField(
                                    controller: amountController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF012249)),
                                    decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Jumlah"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 3,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 201, 232, 255),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedJenis,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                items: ['pemasukan', 'pengeluaran']
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e == 'pemasukan'
                                                ? 'Pemasukan'
                                                : 'Pengeluaran',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      selectedJenis = v;
                                      selectedKategori = null;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 230,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 201, 232, 255),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: validSelectedKategori,
                              isExpanded: true,
                              hint: const Text("Pilih Kategori",
                                  style: TextStyle(fontSize: 13)),
                              items: [
                                ...kategoriItems
                                    .map<DropdownMenuItem<String>>(
                                      (k) => DropdownMenuItem<String>(
                                        value: k['nama'],
                                        child: Text(k['nama'],
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF012249))),
                                      ),
                                    )
                                    .toList(),
                                const DropdownMenuItem<String>(
                                  value: '__tambah__',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add,
                                          size: 18, color: Color(0xFF012249)),
                                      SizedBox(width: 8),
                                      Text("Tambah Kategori",
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF012249))),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) async {
                                if (value == '__tambah__') {
                                  final ctrl = TextEditingController();
                                  final hasil = await showDialog<String>(
                                    context: context,
                                    barrierColor:
                                        Colors.black.withOpacity(0.35),
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.symmetric(
                                          horizontal: 28),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            22, 24, 22, 22),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 25,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 72,
                                              height: 72,
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 201, 232, 255),
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                              ),
                                              child: const Icon(
                                                  Icons.category_outlined,
                                                  size: 34,
                                                  color: Color(0xFF012249)),
                                            ),
                                            const SizedBox(height: 18),
                                            const Text("Tambah Kategori",
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF012249))),
                                            const SizedBox(height: 4),
                                            const Text("untuk transaksi kamu",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                    height: 1.5)),
                                            const SizedBox(height: 22),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 201, 232, 255),
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              child: TextField(
                                                controller: ctrl,
                                                autofocus: true,
                                                style: const TextStyle(
                                                    color: Color(0xFF012249),
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w500),
                                                decoration:
                                                    const InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: "Contoh: Hiburan",
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 16),
                                                  hintStyle: TextStyle(
                                                      color: Colors.grey),
                                                  prefixIcon: Icon(
                                                      Icons.edit_outlined,
                                                      color:
                                                          Color(0xFF012249)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      minimumSize: const Size(
                                                          double.infinity, 52),
                                                      side: BorderSide(
                                                          color: Colors
                                                              .grey.shade300),
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      16)),
                                                    ),
                                                    child: const Text("Batal",
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.grey,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context,
                                                            ctrl.text.trim()),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF6DB5FD),
                                                      elevation: 0,
                                                      minimumSize: const Size(
                                                          double.infinity, 52),
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      16)),
                                                    ),
                                                    child: const Text("Tambah",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                  if (hasil != null && hasil.isNotEmpty) {
                                    await db.insertKategori({
                                      'user_id': userId,
                                      'nama': hasil,
                                      'jenis': selectedJenis,
                                    });
                                    await _loadData();
                                    setState(() => selectedKategori = hasil);
                                    _showTopSnack(
                                        'Kategori berhasil ditambahkan',
                                        icon: Icons.check_circle_outline,
                                        iconColor: Colors.green);
                                  }
                                  return;
                                }
                                setState(() => selectedKategori = value);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _tambahTransaksi,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Tambah",
                            style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 201, 232, 255),
                          foregroundColor: const Color(0xFF012249),
                          elevation: 0,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Container putih list transaksi ──
            Expanded(
              child: Container(
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
                            "Bulan Ini",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF012249),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
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
                      child: allItems.isEmpty
                          ? const Center(
                              child: Text(
                                "Belum ada transaksi bulan ini",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                              itemCount: allItems.length,
                              itemBuilder: (context, index) =>
                                  _transaksiTile(allItems[index]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildTransaksiPage(),
      BudgetPage(key: UniqueKey()),
      const LaporanPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Expanded(child: pages[currentIndex]),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, double amount, IconData icon) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF012249), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(icon, size: 16, color: const Color(0xFF012249)),
            ),
            const SizedBox(height: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              formatRupiah.format(amount),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF012249)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transaksiTile(Map<String, dynamic> t) {
    final isPemasukan = t['jenis'] == 'pemasukan';
    final date = DateTime.parse(t['tanggal']);
    final timeStr = DateFormat('HH:mm - MMM d').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPemasukan
                  ? const Color(0xFF6DB5FD)
                  : const Color(0xFF012249),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(t['kategori_nama'] ?? ''),
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['kategori_nama'] ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF012249)),
                ),
                Text(timeStr,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6DB5FD))),
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
            "${isPemasukan ? '' : '-'}${formatRupiah.format(t['jumlah'])}",
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF012249)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _editTransaksi(t),
            child: const Icon(Icons.edit_outlined,
                size: 16, color: Colors.grey),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _delete(t['id']),
            child: const Icon(Icons.delete_outline,
                size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    final navItems = [
      Icons.credit_card,
      Icons.calculate_outlined,
      Icons.list_alt_outlined,
      Icons.person_outline,
    ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 201, 232, 255),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(45),
          topRight: Radius.circular(45),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (i) {
          final isActive = currentIndex == i;
          return GestureDetector(
            onTap: () async {
              setState(() => currentIndex = i);
              if (i == 0) {
                await _loadData();
                await _loadKategori();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF6DB5FD)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(navItems[i],
                    color: const Color(0xFF012249), size: 32),
              ),
            ),
          );
        }),
      ),
    );
  }
}