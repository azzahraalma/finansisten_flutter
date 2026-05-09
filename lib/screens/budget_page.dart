import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../services/local_auth_service.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final db = DatabaseHelper.instance;
  final auth = LocalAuthService();

  bool isLoading = true;
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> kategoriList = [];

  final currency = NumberFormat.currency(
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
    try {
      final userId = await auth.getUserId();
      if (userId == null) return;

      final budgetData = await db.getBudgetByUser(userId);
      final kategori = await db.getKategoriByUser(userId, jenis: 'pengeluaran');

      final normalizedKategori = kategori
          .map((e) => {...e, 'id': (e['id'] as num).toInt()})
          .toList();

      setState(() {
        budgets = budgetData;
        kategoriList = normalizedKategori;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR LOAD DATA: $e');
      setState(() => isLoading = false);
    }
  }

  void _showBudgetDialog({Map<String, dynamic>? budget}) {
    if (kategoriList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tambahkan kategori pengeluaran terlebih dahulu')),
      );
      return;
    }

    final limitController = TextEditingController(
      text: budget != null
          ? (budget['limit_amount'] as num).toStringAsFixed(0)
          : '',
    );

    final priorityController = TextEditingController(
      text: budget != null
          ? '${(budget['priority'] as num? ?? 1).toInt()}'
          : '',
    );

    int? selectedKategori = budget?['kategori_id'] != null
        ? (budget!['kategori_id'] as num).toInt()
        : null;

    if (selectedKategori != null &&
        !kategoriList.any((e) => e['id'] == selectedKategori)) {
      selectedKategori = null;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + Judul
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 201, 232, 255),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.calculate_outlined,
                          size: 30,
                          color: Color(0xFF012249),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        budget == null ? 'Tambah Budget' : 'Edit Budget',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF012249),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'untuk pengeluaran kamu',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kategori
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF012249),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 201, 232, 255),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedKategori,
                          isExpanded: true,
                          hint: const Text(
                            'Pilih kategori',
                            style: TextStyle(fontSize: 14),
                          ),
                          items: kategoriList
                              .map((e) => DropdownMenuItem<int>(
                                    value: e['id'] as int,
                                    child: Text(
                                      e['nama'] as String,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF012249),
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setModal(() => selectedKategori = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Limit
                    const Text(
                      'Limit Budget',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF012249),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 201, 232, 255),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: limitController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Color(0xFF012249),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),

                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 12, right: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: 1,
                                child: Text(
                                  'Rp',
                                  style: TextStyle(
                                    color: Color(0xFF012249),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Prioritas
                    const Text(
                      'Skala Prioritas',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF012249),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 201, 232, 255),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: priorityController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Color(0xFF012249),
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Contoh: 1, 2, 3...',
                          hintStyle: TextStyle(fontSize: 13, color: Color.fromARGB(255, 2, 1, 64)),
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Tombol
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                if (selectedKategori == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Pilih kategori dulu')),
                                  );
                                  return;
                                }

                                final limit = double.tryParse(
                                    limitController.text.trim());
                                if (limit == null || limit <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Nominal tidak valid')),
                                  );
                                  return;
                                }

                                final priority = int.tryParse(
                                        priorityController.text.trim()) ??
                                    1;
                                final userId = await auth.getUserId();
                                if (userId == null) return;

                                final data = {
                                  'user_id': userId,
                                  'kategori_id': selectedKategori,
                                  'limit_amount': limit,
                                  'priority': priority,
                                  'periode': 'bulanan',
                                };

                                if (budget == null) {
                                  await db.insertBudget(data);
                                } else {
                                  await db.updateBudget(
                                      {...data, 'id': budget['id']});
                                }

                                if (!mounted) return;
                                Navigator.pop(ctx);
                                await _loadData();
                              } catch (e) {
                                debugPrint('ERROR SAVE BUDGET: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6DB5FD),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Simpan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
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
        },
      ),
    );
  }

  Future<void> _deleteBudget(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 30,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Budget',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012249),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Yakin mau hapus budget ini?',
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
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
      await db.deleteBudget(id);
      _loadData();
    }
  }

  IconData _iconForKategori(String nama) {
    switch (nama.toLowerCase()) {
      case 'makanan':
        return Icons.restaurant_outlined;
      case 'transportasi':
        return Icons.directions_bus_outlined;
      case 'belanja':
        return Icons.shopping_bag_outlined;
      case 'kost':
        return Icons.home_outlined;
      case 'hiburan':
        return Icons.confirmation_number_outlined;
      default:
        return Icons.wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6DB5FD),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header — tetap biru, tidak ikut scroll
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF012249),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body putih rounded — ikut scroll sehingga rounded tetap terlihat
            SliverToBoxAdapter(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: CircularProgressIndicator(
                              color: Color(0xFF6DB5FD)),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...budgets.map((e) => _budgetCard(e)),

                          const SizedBox(height: 4),
                          Center(
                            child: ElevatedButton(
                              onPressed: () => _showBudgetDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6DB5FD),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text(
                                'Tambah Budget',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          if (budgets.isNotEmpty) ...[
                            const Text(
                              'Skala Prioritas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF012249),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...budgets.asMap().entries.map((entry) {
                              return _priorityRow(
                                (entry.value['priority'] as num? ??
                                        entry.key + 1)
                                    .toInt(),
                                entry.value,
                              );
                            }),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetCard(Map<String, dynamic> e) {
    final limit = (e['limit_amount'] as num).toDouble();
    final spent = (e['total_spent'] as num).toDouble();
    final percent = (spent / limit * 100).clamp(0.0, 100.0);
    final isWarning = percent >= 40;
    final nama = e['kategori_nama'] as String? ?? '-';
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
          // Icon kategori
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

          // Konten tengah
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama kategori
                Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF012249),
                  ),
                ),
                const SizedBox(height: 6),

                // Progress bar dengan nominal di dalamnya (overlay)
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Background bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: LinearProgressIndicator(
                        minHeight: 22,
                        value: percent / 100,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percent >= 80
                              ? Colors.orange
                              : const Color(0xFF012249),
                        ),
                      ),
                    ),
                    // Nominal sisa di dalam bar
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
                        Text(
                          'Peringatan',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ])
                    else
                      const Row(children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 13),
                        SizedBox(width: 3),
                        Text(
                          'Aman',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Edit & Delete sejajar horizontal
          Row(
            children: [
              GestureDetector(
                onTap: () => _showBudgetDialog(budget: e),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: Color(0xFF012249)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _deleteBudget(e['id']),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priorityRow(int urutan, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF6DB5FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$urutan',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Text(
              item['kategori_nama'] as String? ?? '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF012249),
              ),
            ),
          ),
        ],
      ),
    );
  }
}