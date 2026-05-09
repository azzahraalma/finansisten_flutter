import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // =========================
  // DATABASE
  // =========================

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finansisten.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6, // ← naik dari 5 ke 6
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // =========================
  // CREATE DATABASE
  // =========================

  Future _createDB(Database db, int version) async {
    // TABLE USER
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // TABLE KATEGORI TRANSAKSI
    await db.execute('''
      CREATE TABLE kategori_transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nama TEXT NOT NULL,
        jenis TEXT NOT NULL CHECK(
          jenis IN ('pemasukan', 'pengeluaran')
        ),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // TABLE TRANSAKSI
    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        kategori_id INTEGER NOT NULL,
        jumlah REAL NOT NULL,
        jenis TEXT NOT NULL CHECK(
          jenis IN ('pemasukan', 'pengeluaran')
        ),
        catatan TEXT,
        tanggal TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (kategori_id) REFERENCES kategori_transaksi(id)
      )
    ''');

    // TABLE BUDGET
    await db.execute('''
      CREATE TABLE budget (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        kategori_id INTEGER NOT NULL,
        limit_amount REAL NOT NULL,
        priority INTEGER DEFAULT 1,
        periode TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (kategori_id) REFERENCES kategori_transaksi(id)
      )
    ''');

    // TABLE PRIORITAS BUDGET
    await db.execute('''
      CREATE TABLE prioritas_budget (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        budget_id INTEGER NOT NULL,
        urutan INTEGER NOT NULL,
        FOREIGN KEY (budget_id) REFERENCES budget(id)
      )
    ''');

    // TABLE TABUNGAN
    await db.execute('''
      CREATE TABLE tabungan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nama TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL DEFAULT 0,
        deadline TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // TABLE NOTIFICATIONS — sudah include transaksi_id sejak awal
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipe TEXT,
        judul TEXT,
        pesan TEXT,
        detail TEXT,
        waktu TEXT,
        is_read INTEGER DEFAULT 0,
        transaksi_id INTEGER
      )
    ''');

    // TABLE BUDGET NOTIF STATE
    await db.execute('''
      CREATE TABLE budget_notif_state (
        budget_id INTEGER PRIMARY KEY,
        detail_level INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // =========================
  // ON UPGRADE
  // =========================

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tipe TEXT,
          judul TEXT,
          pesan TEXT,
          detail TEXT,
          waktu TEXT,
          is_read INTEGER DEFAULT 0,
          transaksi_id INTEGER
        )
      ''');
    }

    if (oldVersion < 5) {
      // Tambah kolom transaksi_id kalau belum ada (dari upgrade v4→v5)
      try {
        await db.execute(
          'ALTER TABLE notifications ADD COLUMN transaksi_id INTEGER',
        );
      } catch (_) {}

      // Buat tabel budget_notif_state
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_notif_state (
          budget_id INTEGER PRIMARY KEY,
          detail_level INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 6) {
      // ─── FIX UTAMA ───
      // User yang DB-nya sudah di v5 tapi kolom transaksi_id
      // belum ada (karena upgrade v4→v5 di-skip atau gagal),
      // pastikan kolom ini ada sekarang.
      try {
        await db.execute(
          'ALTER TABLE notifications ADD COLUMN transaksi_id INTEGER',
        );
      } catch (_) {
        // Kolom sudah ada → abaikan error
      }
    }
  }

  // =========================
  // USER
  // =========================

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;

    final existing = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [user['id']],
    );

    if (existing.isEmpty) return 0;

    final oldData = existing.first;
    final updatedData = {
      'username': user['username'] ?? oldData['username'],
      'email': user['email'] ?? oldData['email'],
      'password': user['password'] ?? oldData['password'],
    };

    return await db.update(
      'users',
      updatedData,
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }

  // =========================
  // TRANSAKSI
  // =========================

  Future<int> insertTransaksi(Map<String, dynamic> transaksi) async {
    final db = await database;
    return await db.insert('transaksi', transaksi);
  }

  Future<List<Map<String, dynamic>>> getTransaksiByUser(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        t.*,
        k.nama as kategori_nama
      FROM transaksi t
      JOIN kategori_transaksi k ON t.kategori_id = k.id
      WHERE t.user_id = ?
      ORDER BY t.tanggal DESC
    ''', [userId]);
  }

  Future<int> updateTransaksi(Map<String, dynamic> transaksi) async {
    final db = await database;
    return await db.update(
      'transaksi',
      transaksi,
      where: 'id = ?',
      whereArgs: [transaksi['id']],
    );
  }

  Future<int> deleteTransaksi(int id, {int? userId}) async {
    final db = await database;

    // Hapus notif yang linked ke transaksi ini
    await db.delete(
      'notifications',
      where: 'transaksi_id = ?',
      whereArgs: [id],
    );

    final result = await db.delete(
      'transaksi',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Reset notif state supaya warning bisa trigger ulang
    if (userId != null) {
      await resetBudgetNotifState(userId);
    }

    return result;
  }

  // =========================
  // KATEGORI
  // =========================

  Future<int> insertKategori(Map<String, dynamic> kategori) async {
    final db = await database;

    final nama = kategori['nama'].toString().trim();
    final jenis = kategori['jenis'].toString().toLowerCase().trim();

    final existing = await db.query(
      'kategori_transaksi',
      where: 'user_id = ? AND LOWER(TRIM(nama)) = ? AND LOWER(TRIM(jenis)) = ?',
      whereArgs: [kategori['user_id'], nama.toLowerCase(), jenis],
    );

    if (existing.isNotEmpty) {
      return (existing.first['id'] as num).toInt();
    }

    return await db.insert(
      'kategori_transaksi',
      {...kategori, 'nama': nama, 'jenis': jenis},
    );
  }

  Future<List<Map<String, dynamic>>> getKategoriByUser(
    int userId, {
    String? jenis,
  }) async {
    final db = await database;

    if (jenis != null) {
      return await db.query(
        'kategori_transaksi',
        where: 'user_id = ? AND LOWER(TRIM(jenis)) = ?',
        whereArgs: [userId, jenis.toLowerCase().trim()],
        orderBy: 'nama ASC',
      );
    }

    return await db.query(
      'kategori_transaksi',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'nama ASC',
    );
  }

  // =========================
  // BUDGET
  // =========================

  Future<int> insertBudget(Map<String, dynamic> budget) async {
    final db = await database;

    final existing = await db.query(
      'budget',
      where: 'user_id = ? AND kategori_id = ?',
      whereArgs: [budget['user_id'], budget['kategori_id']],
    );

    if (existing.isNotEmpty) {
      throw Exception('Budget kategori sudah ada');
    }

    return await db.insert('budget', budget);
  }

  Future<List<Map<String, dynamic>>> getBudgetByUser(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        b.id,
        b.user_id,
        b.kategori_id,
        b.limit_amount,
        b.priority,
        b.periode,
        k.nama as kategori_nama,
        COALESCE(
          SUM(
            CASE
              WHEN LOWER(TRIM(t.jenis)) = 'pengeluaran'
              THEN t.jumlah
              ELSE 0
            END
          ),
        0) as total_spent
      FROM budget b
      JOIN kategori_transaksi k ON k.id = b.kategori_id
      LEFT JOIN transaksi t
        ON t.kategori_id = b.kategori_id
        AND t.user_id = b.user_id
      WHERE b.user_id = ?
      GROUP BY b.id
      ORDER BY b.priority ASC
    ''', [userId]);
  }

  Future<int> updateBudget(Map<String, dynamic> budget) async {
    final db = await database;
    return await db.update(
      'budget',
      budget,
      where: 'id = ?',
      whereArgs: [budget['id']],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;

    await db.delete(
      'budget_notif_state',
      where: 'budget_id = ?',
      whereArgs: [id],
    );

    return await db.delete(
      'budget',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // TABUNGAN
  // =========================

  Future<int> insertTabungan(Map<String, dynamic> tabungan) async {
    final db = await database;
    return await db.insert('tabungan', tabungan);
  }

  Future<List<Map<String, dynamic>>> getTabunganByUser(int userId) async {
    final db = await database;
    return await db.query(
      'tabungan',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateTabungan(Map<String, dynamic> tabungan) async {
    final db = await database;
    return await db.update(
      'tabungan',
      tabungan,
      where: 'id = ?',
      whereArgs: [tabungan['id']],
    );
  }

  Future<int> deleteTabungan(int id) async {
    final db = await database;
    return await db.delete(
      'tabungan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // NOTIFICATIONS
  // =========================

  Future<int> insertNotification(Map<String, dynamic> notif) async {
    final db = await database;
    return await db.insert('notifications', notif);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final db = await database;
    return await db.query(
      'notifications',
      orderBy: 'waktu DESC',
    );
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearNotifications() async {
    final db = await database;
    return await db.delete('notifications');
  }

  Future<int> markNotificationAsRead(int id) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> unreadNotificationCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM notifications
      WHERE is_read = 0
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // =========================
  // BUDGET WARNING
  // Logic: setiap budget punya "threshold level"
  // 0=aman, 1=>=40%, 2=>=80%, 3=>=100%
  // Notif hanya dikirim kalau level NAIK ke lebih tinggi.
  // Kalau transaksi dihapus → percent turun → resetBudgetNotifState
  // dipanggil → level reset → pas tambah lagi bisa trigger notif ulang.
  // =========================

  int _thresholdLevel(double percent) {
    if (percent >= 100) return 3;
    if (percent >= 80) return 2;
    if (percent >= 40) return 1;
    return 0;
  }

  Future<void> resetBudgetNotifState(int userId) async {
    final db = await database;
    final budgets = await getBudgetByUser(userId);

    for (final b in budgets) {
      final budgetId = (b['id'] as num).toInt();
      final limit = (b['limit_amount'] as num).toDouble();
      final spent = (b['total_spent'] as num).toDouble();
      final percent = (spent / limit * 100).clamp(0.0, 100.0);
      final currentLevel = _thresholdLevel(percent);

      await db.execute('''
        INSERT OR REPLACE INTO budget_notif_state (budget_id, detail_level)
        VALUES (?, ?)
      ''', [budgetId, currentLevel]);
    }
  }

  Future<List<Map<String, dynamic>>> checkBudgetWarning(
    int userId,
    int transaksiId,
  ) async {
    final budgets = await getBudgetByUser(userId);
    final warnings = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final db = await database;

    for (final b in budgets) {
      final budgetId = (b['id'] as num).toInt();
      final limit = (b['limit_amount'] as num).toDouble();
      final spent = (b['total_spent'] as num).toDouble();
      final percent = (spent / limit * 100).clamp(0.0, 100.0);
      final nama = b['kategori_nama'] as String? ?? '-';
      final currentLevel = _thresholdLevel(percent);

      final lastRow = await db.rawQuery('''
        SELECT detail_level FROM budget_notif_state
        WHERE budget_id = ?
        LIMIT 1
      ''', [budgetId]);

      final lastLevel = lastRow.isNotEmpty
          ? (lastRow.first['detail_level'] as num).toInt()
          : 0;

      if (currentLevel > lastLevel && currentLevel > 0) {
        String judul;
        String pesan;

        if (currentLevel == 3) {
          judul = 'Budget $nama Habis! 🚨';
          pesan = 'Budget $nama sudah terpakai 100%. Kamu sudah melebihi limit!';
        } else if (currentLevel == 2) {
          judul = 'Budget $nama Hampir Habis ⚠️';
          pesan = 'Budget $nama sudah terpakai ${percent.toStringAsFixed(0)}%. Hati-hati!';
        } else {
          judul = 'Peringatan Budget $nama';
          pesan = 'Budget $nama sudah terpakai ${percent.toStringAsFixed(0)}%.';
        }

        final sisa = limit - spent;
        final sisaStr = sisa <= 0
            ? 'Limit terlampaui!'
            : 'Sisa Rp ${sisa.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';

        await insertNotification({
          'tipe': 'warning_budget',
          'judul': judul,
          'pesan': pesan,
          'detail': sisaStr,
          'waktu': now.toIso8601String(),
          'is_read': 0,
          'transaksi_id': transaksiId,
        });

        await db.execute('''
          INSERT OR REPLACE INTO budget_notif_state (budget_id, detail_level)
          VALUES (?, ?)
        ''', [budgetId, currentLevel]);

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

  // =========================
  // LAPORAN
  // =========================

  Future<List<Map<String, dynamic>>> getLaporanByPeriode(
    int userId,
    String dari,
    String sampai,
  ) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        t.*,
        k.nama as kategori_nama
      FROM transaksi t
      JOIN kategori_transaksi k ON t.kategori_id = k.id
      WHERE t.user_id = ?
        AND t.tanggal BETWEEN ? AND ?
      ORDER BY t.tanggal DESC
    ''', [userId, dari, sampai]);
  }

  Future<Map<String, dynamic>> getSummaryLaporan(
    int userId,
    String dari,
    String sampai,
  ) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN jenis = 'pemasukan' THEN jumlah ELSE 0 END) as total_pemasukan,
        SUM(CASE WHEN jenis = 'pengeluaran' THEN jumlah ELSE 0 END) as total_pengeluaran
      FROM transaksi
      WHERE user_id = ?
        AND tanggal BETWEEN ? AND ?
    ''', [userId, dari, sampai]);
    return result.first;
  }

  // =========================
  // CLOSE DATABASE
  // =========================

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}