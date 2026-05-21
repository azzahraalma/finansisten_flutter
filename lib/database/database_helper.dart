import '../services/auth_service.dart';
import 'firestore_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  final _auth = AuthService.instance;
  final _db = FirestoreService.instance;

  Future<List<Map<String, dynamic>>> getKategoriByUser(
    String uid, {
    String? jenis,
  }) async {
    return _db.getKategoriByUser(uid, jenis: jenis);
  }

  Future<String> insertKategori(Map<String, dynamic> data) async {
    final uid = data['user_id']?.toString();
    if (uid == null || uid.isEmpty) {
      throw Exception('User ID diperlukan untuk menyimpan kategori');
    }
    return _db.insertKategori(uid, data);
  }

  Future<List<Map<String, dynamic>>> getBudgetByUser(String uid) async {
    return _db.getBudgetByUser(uid);
  }

  Future<String> insertBudget(Map<String, dynamic> data) async {
    final uid = data['user_id']?.toString();
    if (uid == null || uid.isEmpty) {
      throw Exception('User ID diperlukan untuk menyimpan budget');
    }
    return _db.insertBudget(uid, data);
  }

  Future<void> updateBudget(Map<String, dynamic> data) async {
    final uid = data['user_id']?.toString();
    final budgetId = data['id']?.toString();
    if (uid == null || uid.isEmpty || budgetId == null || budgetId.isEmpty) {
      return;
    }

    final payload = Map<String, dynamic>.from(data);
    payload.remove('id');
    payload.remove('user_id');
    await _db.updateBudget(uid, budgetId, payload);
  }

  Future<void> deleteBudget(String budgetId) async {
    final uid = _auth.getUserId();
    if (uid == null) return;
    await _db.deleteBudget(uid, budgetId);
  }

  Future<List<Map<String, dynamic>>> getNotificationsByUser(String uid) async {
    return _db.getNotifications(uid);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final uid = _auth.getUserId();
    if (uid == null) return [];
    return getNotificationsByUser(uid);
  }

  Future<void> clearNotifications() async {
    final uid = _auth.getUserId();
    if (uid == null) return;
    await _db.clearNotifications(uid);
  }

  Future<void> deleteNotification(String notifId) async {
    final uid = _auth.getUserId();
    if (uid == null) return;
    await _db.deleteNotification(uid, notifId);
  }

  Future<String> insertNotification(Map<String, dynamic> data) async {
    final uid = _auth.getUserId();
    if (uid == null) {
      throw Exception('User harus login untuk menyimpan notifikasi');
    }
    return _db.insertNotification(uid, data);
  }

  Future<List<Map<String, dynamic>>> getLaporanByPeriode(
    String uid,
    String dari,
    String sampai,
  ) async {
    return _db.getLaporanByPeriode(uid, dari, sampai);
  }

  Future<Map<String, dynamic>> getSummaryLaporan(
    String uid,
    String dari,
    String sampai,
  ) async {
    return _db.getSummaryLaporan(uid, dari, sampai);
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    return _db.getUserProfile(uid);
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    final uid = data['id']?.toString();
    if (uid == null || uid.isEmpty) return;

    final payload = Map<String, dynamic>.from(data);
    payload.remove('id');
    await _db.updateUserProfile(uid, payload);
  }
}
