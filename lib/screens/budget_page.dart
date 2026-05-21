import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../services/local_auth_service.dart';
import '../widgets/budget/budget_card.dart';
import '../widgets/budget/priority_row.dart';
import '../widgets/budget/budget_dialog.dart';

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

      setState(() {
        budgets = budgetData;
        kategoriList = kategori
            .map((e) => {...e, 'id': e['id']?.toString()})
            .toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR LOAD DATA: $e');
      setState(() => isLoading = false);
    }
  }

  void _openBudgetDialog({Map<String, dynamic>? budget}) {
    BudgetDialog.show(
      context,
      budget: budget,
      kategoriList: kategoriList,
      onSaved: _loadData,
    );
  }

  Future<void> _deleteBudget(String id) async {
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
                child: const Icon(Icons.delete_outline, size: 30, color: Colors.red),
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
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6DB5FD),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Center(
                  child: Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012249),
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ──
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
                          child: CircularProgressIndicator(color: Color(0xFF6DB5FD)),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Budget cards
                          ...budgets.map(
                            (e) => BudgetCard(
                              budget: e,
                              currency: currency,
                              onEdit: () => _openBudgetDialog(budget: e),
                              onDelete: () => _deleteBudget(e['id']),
                            ),
                          ),

                          const SizedBox(height: 4),
                          Center(
                            child: ElevatedButton(
                              onPressed: () => _openBudgetDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6DB5FD),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Tambah Budget',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                          // Skala prioritas
                          if (budgets.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            const Text(
                              'Skala Prioritas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF012249),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...budgets.asMap().entries.map(
                                  (entry) => PriorityRow(
                                    urutan: (entry.value['priority'] as num? ??
                                            entry.key + 1)
                                        .toInt(),
                                    item: entry.value,
                                  ),
                                ),
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
}