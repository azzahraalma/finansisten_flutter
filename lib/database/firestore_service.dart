import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  FirestoreService._init();

  final _db = FirebaseFirestore.instance;

  CollectionReference _users() => _db.collection('users');

  CollectionReference _kategori(String uid) =>
      _users().doc(uid).collection('kategori_transaksi');

  CollectionReference _transaksi(String uid) =>
      _users().doc(uid).collection('transaksi');

  CollectionReference _budget(String uid) =>
      _users().doc(uid).collection('budget');

  CollectionReference _tabungan(String uid) =>
      _users().doc(uid).collection('tabungan');

  CollectionReference _notifications(String uid) =>
      _users().doc(uid).collection('notifications');

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _users().doc(uid).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _users().doc(uid).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _users().doc(uid).update(data);
  }

  Future<String> insertKategori(String uid, Map<String, dynamic> data) async {
    final nama = data['nama'].toString().trim().toLowerCase();
    final jenis = data['jenis'].toString().trim().toLowerCase();

    final existing = await _kategori(uid)
        .where('nama_lower', isEqualTo: nama)
        .where('jenis', isEqualTo: jenis)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final ref = await _kategori(uid).add({
      ...data,
      'nama': data['nama'].toString().trim(),
      'jenis': jenis,
      'nama_lower': nama,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> getKategoriByUser(
    String uid, {
    String? jenis,
  }) async {
    Query q = _kategori(uid).orderBy('nama');
    if (jenis != null) {
      q = q.where('jenis', isEqualTo: jenis.toLowerCase().trim());
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => {'id': d.id, ...Map<String, dynamic>.from(d.data() as Map)})
        .toList();
  }

  Future<String> insertTransaksi(String uid, Map<String, dynamic> data) async {
    final ref = await _transaksi(uid).add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> getTransaksiByUser(String uid) async {
    final snap = await _transaksi(uid)
        .orderBy('tanggal', descending: true)
        .get();

    final List<Map<String, dynamic>> result = [];

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;

      String kategoriNama = '-';
      if (data['kategori_id'] != null) {
        final katDoc =
            await _kategori(uid).doc(data['kategori_id']).get();
        if (katDoc.exists) {
          kategoriNama =
              (katDoc.data() as Map<String, dynamic>)['nama'] ?? '-';
        }
      }
      result.add({
        'id': doc.id,
        ...data,
        'kategori_nama': kategoriNama,
      });
    }
    return result;
  }

  Future<void> updateTransaksi(
      String uid, String transaksiId, Map<String, dynamic> data) async {
    await _transaksi(uid).doc(transaksiId).update(data);
  }

  Future<void> deleteTransaksi(String uid, String transaksiId) async {

    final notifSnap = await _notifications(uid)
        .where('transaksi_id', isEqualTo: transaksiId)
        .get();
    for (final d in notifSnap.docs) {
      await d.reference.delete();
    }
    await _transaksi(uid).doc(transaksiId).delete();
    await resetBudgetNotifState(uid);
  }

  Future<String> insertBudget(String uid, Map<String, dynamic> data) async {
    final existing = await _budget(uid)
        .where('kategori_id', isEqualTo: data['kategori_id'])
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) throw Exception('Budget kategori sudah ada');

    final ref = await _budget(uid).add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> getBudgetByUser(String uid) async {
    final budgetSnap =
        await _budget(uid).orderBy('priority').get();
    final transaksiSnap = await _transaksi(uid)
        .where('jenis', isEqualTo: 'pengeluaran')
        .get();

    final List<Map<String, dynamic>> result = [];

    for (final bDoc in budgetSnap.docs) {
      final b = bDoc.data() as Map<String, dynamic>;
      final kategoriId = b['kategori_id'] as String?;

      String kategoriNama = '-';
      if (kategoriId != null) {
        final katDoc = await _kategori(uid).doc(kategoriId).get();
        if (katDoc.exists) {
          kategoriNama =
              (katDoc.data() as Map<String, dynamic>)['nama'] ?? '-';
        }
      }

      double totalSpent = 0;
      for (final t in transaksiSnap.docs) {
        final tData = t.data() as Map<String, dynamic>;
        if (tData['kategori_id'] == kategoriId) {
          totalSpent += (tData['jumlah'] as num).toDouble();
        }
      }

      result.add({
        'id': bDoc.id,
        ...b,
        'kategori_nama': kategoriNama,
        'total_spent': totalSpent,
      });
    }
    return result;
  }

  Future<void> updateBudget(
      String uid, String budgetId, Map<String, dynamic> data) async {
    await _budget(uid).doc(budgetId).update(data);
  }

  Future<void> deleteBudget(String uid, String budgetId) async {
    await _users()
        .doc(uid)
        .collection('budget_notif_state')
        .doc(budgetId)
        .delete();
    await _budget(uid).doc(budgetId).delete();
  }

  Future<String> insertTabungan(String uid, Map<String, dynamic> data) async {
    final ref = await _tabungan(uid).add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> getTabunganByUser(String uid) async {
    final snap = await _tabungan(uid).get();
    return snap.docs
        .map((d) => {'id': d.id, ...Map<String, dynamic>.from(d.data() as Map)})
        .toList();
  }

  Future<void> updateTabungan(
      String uid, String tabunganId, Map<String, dynamic> data) async {
    await _tabungan(uid).doc(tabunganId).update(data);
  }

  Future<void> deleteTabungan(String uid, String tabunganId) async {
    await _tabungan(uid).doc(tabunganId).delete();
  }

  Future<String> insertNotification(
      String uid, Map<String, dynamic> data) async {
    final ref = await _notifications(uid).add(data);
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> getNotifications(String uid) async {
    final snap = await _notifications(uid)
        .orderBy('waktu', descending: true)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...Map<String, dynamic>.from(d.data() as Map)})
        .toList();
  }

  Future<void> deleteNotification(String uid, String notifId) async {
    await _notifications(uid).doc(notifId).delete();
  }

  Future<void> clearNotifications(String uid) async {
    final snap = await _notifications(uid).get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  Future<void> markNotificationAsRead(String uid, String notifId) async {
    await _notifications(uid).doc(notifId).update({'is_read': true});
  }

  Future<int> unreadNotificationCount(String uid) async {
    final snap = await _notifications(uid)
        .where('is_read', isEqualTo: false)
        .get();
    return snap.docs.length;
  }

  int _thresholdLevel(double percent) {
    if (percent >= 100) return 3;
    if (percent >= 80) return 2;
    if (percent >= 40) return 1;
    return 0;
  }

  CollectionReference _budgetNotifState(String uid) =>
      _users().doc(uid).collection('budget_notif_state');

  Future<void> resetBudgetNotifState(String uid) async {
    final budgets = await getBudgetByUser(uid);
    for (final b in budgets) {
      final budgetId = b['id'] as String;
      final limit = (b['limit_amount'] as num).toDouble();
      final spent = (b['total_spent'] as num).toDouble();
      final percent = (spent / limit * 100).clamp(0.0, 100.0);
      final currentLevel = _thresholdLevel(percent);

      await _budgetNotifState(uid)
          .doc(budgetId)
          .set({'detail_level': currentLevel});
    }
  }

  Future<List<Map<String, dynamic>>> checkBudgetWarning(
    String uid,
    String transaksiId,
  ) async {
    final budgets = await getBudgetByUser(uid);
    final warnings = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (final b in budgets) {
      final budgetId = b['id'] as String;
      final limit = (b['limit_amount'] as num).toDouble();
      final spent = (b['total_spent'] as num).toDouble();
      final percent = (spent / limit * 100).clamp(0.0, 100.0);
      final nama = b['kategori_nama'] as String? ?? '-';
      final currentLevel = _thresholdLevel(percent);

      final lastDoc =
          await _budgetNotifState(uid).doc(budgetId).get();
      final lastLevel = lastDoc.exists
          ? ((lastDoc.data() as Map)['detail_level'] as num).toInt()
          : 0;

      if (currentLevel > lastLevel && currentLevel > 0) {
        String judul;
        String pesan;

        if (currentLevel == 3) {
          judul = 'Budget $nama Habis! 🚨';
          pesan = 'Budget $nama sudah terpakai 100%. Kamu sudah melebihi limit!';
        } else if (currentLevel == 2) {
          judul = 'Budget $nama Hampir Habis ⚠️';
          pesan =
              'Budget $nama sudah terpakai ${percent.toStringAsFixed(0)}%. Hati-hati!';
        } else {
          judul = 'Peringatan Budget $nama';
          pesan =
              'Budget $nama sudah terpakai ${percent.toStringAsFixed(0)}%.';
        }

        final sisa = limit - spent;
        final sisaStr = sisa <= 0
            ? 'Limit terlampaui!'
            : 'Sisa Rp ${sisa.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';

        await insertNotification(uid, {
          'tipe': 'warning_budget',
          'judul': judul,
          'pesan': pesan,
          'detail': sisaStr,
          'waktu': now.toIso8601String(),
          'is_read': false,
          'transaksi_id': transaksiId,
        });

        await _budgetNotifState(uid)
            .doc(budgetId)
            .set({'detail_level': currentLevel});

        warnings.add({
          'judul': judul,
          'pesan': pesan,
          'percent': percent,
          'nama': nama,
        });
      }
    }
    return warnings;
  }

  Future<List<Map<String, dynamic>>> getLaporanByPeriode(
    String uid,
    String dari,
    String sampai,
  ) async {
    final snap = await _transaksi(uid)
        .where('tanggal', isGreaterThanOrEqualTo: dari)
        .where('tanggal', isLessThanOrEqualTo: sampai)
        .orderBy('tanggal', descending: true)
        .get();

    final List<Map<String, dynamic>> result = [];
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String kategoriNama = '-';
      if (data['kategori_id'] != null) {
        final katDoc = await _kategori(uid).doc(data['kategori_id']).get();
        if (katDoc.exists) {
          kategoriNama =
              (katDoc.data() as Map<String, dynamic>)['nama'] ?? '-';
        }
      }
      result.add({'id': doc.id, ...data, 'kategori_nama': kategoriNama});
    }
    return result;
  }

  Future<Map<String, dynamic>> getSummaryLaporan(
    String uid,
    String dari,
    String sampai,
  ) async {
    final snap = await _transaksi(uid)
        .where('tanggal', isGreaterThanOrEqualTo: dari)
        .where('tanggal', isLessThanOrEqualTo: sampai)
        .get();

    double pemasukan = 0, pengeluaran = 0;
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final jumlah = (data['jumlah'] as num).toDouble();
      if (data['jenis'] == 'pemasukan') {
        pemasukan += jumlah;
      } else {
        pengeluaran += jumlah;
      }
    }
    return {
      'total_pemasukan': pemasukan,
      'total_pengeluaran': pengeluaran,
    };
  }
}