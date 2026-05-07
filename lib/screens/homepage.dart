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

  // Notifikasi
  List<Map<String, dynamic>> notifikasiList = []; 
  bool hasNotification = false;

  double totalPemasukan = 0;
  double totalPengeluaran = 0;

  final amountController = TextEditingController();
  final kategoriController = TextEditingController();
  String selectedJenis = 'pemasukan';

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
    userId = await auth.getUserId();
    if (userId == null) return;

    final transaksi = await db.getTransaksiByUser(userId!);
    final kategori = await db.getKategoriByUser(userId!);

    if (kategori.isEmpty) {
      await _insertDefaultKategori();
      kategoriList = await db.getKategoriByUser(userId!);
    } else {
      kategoriList = kategori;
    }

    double masuk = 0, keluar = 0;
    for (var t in transaksi) {
      final date = DateTime.parse(t['tanggal']);
      if (date.month == selectedMonth.month && date.year == selectedMonth.year) {
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

  void _showSuccessPopup() {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) {
      return Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  size: 80, color: Color(0xFF6DB5FD)),
              const SizedBox(height: 16),
              const Text(
                "Transaksi Berhasil\nDitambahkan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6DB5FD),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Future.delayed(const Duration(milliseconds: 5000), () {
    if (mounted) Navigator.pop(context);
  });
}

  void _addNotifikasi({
    required String judul,
    required String pesan,
    String? detail,
    String tipe = 'transaksi',
  }) {
    setState(() {
      notifikasiList.insert(0, {
        'judul': judul,
        'pesan': pesan,
        'detail': detail,
        'tipe': tipe,
        'waktu': DateTime.now().toIso8601String(),
      });
      hasNotification = true;
    });
  }

  Future<void> _tambahTransaksi() async {
    final clean = amountController.text.replaceAll('.', '');
    final amount = double.tryParse(clean);
    final namaKategori = kategoriController.text.trim();

    if (amount == null || namaKategori.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi jumlah dan kategori dengan benar")),
      );
      return;
    }

    int kategoriId;
    final existing = kategoriList.where(
      (k) =>
          k['nama'].toString().toLowerCase() ==
              namaKategori.toLowerCase() &&
          k['jenis'] == selectedJenis,
    ).toList();

    if (existing.isNotEmpty) {
      kategoriId = existing.first['id'];
    } else {
      kategoriId = await db.insertKategori({
        'nama': namaKategori,
        'jenis': selectedJenis,
        'user_id': userId,
      });
    }

    await db.insertTransaksi({
      'user_id': userId,
      'kategori_id': kategoriId,
      'jumlah': amount,
      'jenis': selectedJenis,
      'tanggal': DateTime.now().toIso8601String(),
    });
    _showSuccessPopup(); 

    _addNotifikasi(
      judul: selectedJenis == 'pemasukan'
          ? 'Pemasukan'
          : 'Pengeluaran',
      pesan: '${formatRupiah.format(amount)} untuk $namaKategori',
      detail:
          '$namaKategori | ${selectedJenis == 'pemasukan' ? '+' : '-'}${formatRupiah.format(amount)}',
      tipe: selectedJenis,
    );

    amountController.clear();
    kategoriController.clear();

    await _loadData();
  }

Future<void> _delete(int id) async {
  final confirm = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.25),
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      title: const Text(
        "Hapus Transaksi",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF012249),
        ),
      ),

      content: const Text(
        "Yakin ingin menghapus transaksi ini?",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
          height: 1.4,
        ),
      ),

      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Batal"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Hapus",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  if (confirm == true) {
    await db.deleteTransaksi(id);
    _loadData();
  }
}

void _editTransaksi(Map<String, dynamic> t) {
  final controller = TextEditingController(
    text: t['jumlah'].toString().replaceAll('.0', ''),
  );

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.25), 
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
      ),

      title: const Text(
        "Edit Transaksi",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF012249),
        ),
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 201, 232, 255),              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text(
                  "Rp ",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF012249),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true, 
                    cursorColor: const Color(0xFF012249),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Masukkan jumlah",
                    ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final value =
                      double.tryParse(controller.text.replaceAll('.', ''));
                  if (value == null) return;

                  await db.updateTransaksi({
                    'id': t['id'],
                    'jumlah': value,
                  });

                  Navigator.pop(context);
                  _loadData();
                },
                child: const Text(
                  "Simpan",
                  style: TextStyle(color: Colors.white),
                ),
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

  Map<String, List<Map<String, dynamic>>> _groupByMonth() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final filtered = transaksiList.where((t) {
      final date = DateTime.parse(t['tanggal']);
      return date.month == selectedMonth.month && date.year == selectedMonth.year;
    }).toList();

    for (var t in filtered) {
      final date = DateTime.parse(t['tanggal']);
      final now = DateTime.now();
      final key = (date.month == now.month && date.year == now.year)
          ? 'Bulan Ini'
          : DateFormat('MMMM yyyy', 'id_ID').format(date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  Widget _buildTransaksiPage() {
    final grouped = _groupByMonth();
    final allItems = <Map<String, dynamic>>[];
    grouped.forEach((_, items) => allItems.addAll(items));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xFF6DB5FD),
            child: Column(
              children: [
                // Navbar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                              builder: (_) => NotifikasiPage(
                                notifikasiList: notifikasiList,
                                onClear: () {
                                  setState(() {
                                    notifikasiList.clear();
                                    hasNotification = false;
                                  });
                                },
                              ),
                            ),
                          ).then((_) {

                            setState(() => hasNotification = false);
                          });
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

                // Summary Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _summaryCard("Pengeluaran", totalPengeluaran, Icons.arrow_outward),
                      const SizedBox(width: 12),
                      _summaryCard("Pemasukan", totalPemasukan, Icons.south_west),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tambah Transaksi 
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
                                    color: Color.fromARGB(255, 201, 232, 255),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        "Rp ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF012249),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: amountController,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF012249),
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            hintText: "Jumlah",
                                          ),
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
                                    color: Color.fromARGB(255, 201, 232, 255),
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
                                                  e == 'pemasukan' ? 'Pemasukan' : 'Pengeluaran',
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => selectedJenis = v);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                        Center(
                          child: SizedBox(
                            width: 260, 
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 201, 232, 255),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.category_outlined,
                                    color: Color(0xFF012249),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: kategoriController,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF012249),
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Kategori (makan, gaji, dll)",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _tambahTransaksi,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Tambah",
                                style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 201, 232, 255),
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

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                  const SizedBox(height: 12),
                  allItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              "Belum ada transaksi bulan ini",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allItems.length,
                          itemBuilder: (context, index) =>
                              _transaksiTile(allItems[index]),
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildTransaksiPage(),
      const BudgetPage(),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF012249), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF012249)),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              formatRupiah.format(amount),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF012249),
              ),
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
                    color: Color(0xFF012249),
                  ),
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
              color: Color(0xFF012249),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _editTransaksi(t),
            child: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _delete(t['id']),
            child: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
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
            onTap: () => setState(() => currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF6DB5FD) : Colors.transparent,
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