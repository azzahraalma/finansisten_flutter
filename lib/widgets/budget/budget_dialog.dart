import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../services/local_auth_service.dart';
import 'tambah_kategori_dialog.dart';

class BudgetDialog extends StatefulWidget {
  final Map<String, dynamic>? budget;
  final List<Map<String, dynamic>> kategoriList;
  final VoidCallback onSaved;

  const BudgetDialog({
    super.key,
    this.budget,
    required this.kategoriList,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? budget,
    required List<Map<String, dynamic>> kategoriList,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => BudgetDialog(
        budget: budget,
        kategoriList: kategoriList,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  final db = DatabaseHelper.instance;
  final auth = LocalAuthService();

  late final TextEditingController limitController;
  late final TextEditingController priorityController;
  String? selectedKategori;
  late List<Map<String, dynamic>> kategoriList;

  @override
void initState() {
  super.initState();
  kategoriList = List.from(widget.kategoriList);

  limitController = TextEditingController(
    text: widget.budget != null
        ? (widget.budget!['limit_amount'] as num).toStringAsFixed(0)
        : '',
  );
  priorityController = TextEditingController(
    text: widget.budget != null
        ? '${(widget.budget!['priority'] as num? ?? 1).toInt()}'
        : '',
  );

  selectedKategori = widget.budget?['kategori_id']?.toString();

  if (selectedKategori != null &&
      !kategoriList.any((e) => e['id'] == selectedKategori)) {
    selectedKategori = null;
  }

  // Tambahan: load default kalau kosong
  if (kategoriList.isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDefaultKategori());
  }
}

Future<void> _ensureDefaultKategori() async {
  final userId = await auth.getUserId();
  if (userId == null) return;

  final existing = await db.getKategoriByUser(userId, jenis: 'pengeluaran');
  if (existing.isNotEmpty) {
    setState(() => kategoriList = existing);
    return;
  }

  // Insert default kategori pengeluaran
  final defaults = ['Belanja', 'Kost', 'Transportasi', 'Makanan'];
  for (final nama in defaults) {
    await db.insertKategori({
      'user_id': userId,
      'nama': nama,
      'jenis': 'pengeluaran',
    });
  }

  final updated = await db.getKategoriByUser(userId, jenis: 'pengeluaran');
  setState(() => kategoriList = updated);
}

  @override
  void dispose() {
    limitController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  Future<void> _handleTambahKategori() async {
    final hasil = await TambahKategoriDialog.show(context);
    if (hasil != null && hasil.isNotEmpty) {
      final userId = await auth.getUserId();
      if (userId == null) return;

      final newId = await db.insertKategori({
        'user_id': userId,
        'nama': hasil,
        'jenis': 'pengeluaran',
      });

      final updatedKategori =
          await db.getKategoriByUser(userId, jenis: 'pengeluaran');

      setState(() {
        kategoriList = updatedKategori;
        selectedKategori = newId;
      });
    }
  }

  Future<void> _save() async {
    if (selectedKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori dulu')),
      );
      return;
    }

    final limit = double.tryParse(limitController.text.trim());
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal tidak valid')),
      );
      return;
    }

    final priority = int.tryParse(priorityController.text.trim()) ?? 1;
    final userId = await auth.getUserId();
    if (userId == null) return;

    final data = {
      'user_id': userId,
      'kategori_id': selectedKategori,
      'limit_amount': limit,
      'priority': priority,
      'periode': 'bulanan',
    };

    if (widget.budget == null) {
      await db.insertBudget(data);
    } else {
      await db.updateBudget({...data, 'id': widget.budget!['id']});
    }

    if (!mounted) return;
    Navigator.pop(context);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
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
              // ── Header ──
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 201, 232, 255),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.calculate_outlined,
                      size: 30, color: Color(0xFF012249)),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  widget.budget == null ? 'Tambah Budget' : 'Edit Budget',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012249)),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text('untuk pengeluaran kamu',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
              const SizedBox(height: 24),

              // ── Kategori ──
              _label('Kategori'),
              const SizedBox(height: 8),
              _inputBox(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedKategori,
                    isExpanded: true,
                    hint: const Text('Pilih kategori',
                        style: TextStyle(fontSize: 14)),
                    items: [
                      ...kategoriList.map(
                        (e) => DropdownMenuItem<String>(
                          value: e['id']?.toString(),
                          child: Text(e['nama'] as String,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF012249))),
                        ),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'add',
                        child: Row(children: [
                          Icon(Icons.add, size: 18, color: Color(0xFF012249)),
                          SizedBox(width: 8),
                          Text('Tambah Kategori',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF012249))),
                        ]),
                      ),
                    ],
                    onChanged: (v) async {
                      if (v == 'add') {
                        await _handleTambahKategori();
                      } else {
                        setState(() => selectedKategori = v);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Limit ──
              _label('Limit Budget'),
              const SizedBox(height: 8),
              _inputBox(
                child: TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: Color(0xFF012249), fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        child: Text('Rp',
                            style: TextStyle(
                                color: Color(0xFF012249),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Prioritas ──
              _label('Skala Prioritas'),
              const SizedBox(height: 8),
              _inputBox(
                child: TextField(
                  controller: priorityController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: Color(0xFF012249), fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Contoh: 1, 2, 3...',
                    hintStyle: TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(255, 131, 131, 142)),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Tombol ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6DB5FD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Simpan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF012249)),
      );

  Widget _inputBox({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 201, 232, 255),
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      );
}