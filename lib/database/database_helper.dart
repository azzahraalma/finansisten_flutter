import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finansisten.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

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
        jenis TEXT NOT NULL CHECK(jenis IN ('pemasukan', 'pengeluaran')),
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
        jenis TEXT NOT NULL CHECK(jenis IN ('pemasukan', 'pengeluaran')),
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
  }

  //  USER 
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users',
        where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.update('users', user,
        where: 'id = ?', whereArgs: [user['id']]);
  }

  //  TRANSAKSI 
  Future<int> insertTransaksi(Map<String, dynamic> transaksi) async {
    final db = await database;
    return await db.insert('transaksi', transaksi);
  }

  Future<List<Map<String, dynamic>>> getTransaksiByUser(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, k.nama as kategori_nama 
      FROM transaksi t
      JOIN kategori_transaksi k ON t.kategori_id = k.id
      WHERE t.user_id = ?
      ORDER BY t.tanggal DESC
    ''', [userId]);
  }

  Future<int> updateTransaksi(Map<String, dynamic> transaksi) async {
    final db = await database;
    return await db.update('transaksi', transaksi,
        where: 'id = ?', whereArgs: [transaksi['id']]);
  }

  Future<int> deleteTransaksi(int id) async {
    final db = await database;
    return await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }

  //  KATEGORI 
  Future<int> insertKategori(Map<String, dynamic> kategori) async {
    final db = await database;
    return await db.insert('kategori_transaksi', kategori);
  }

  Future<List<Map<String, dynamic>>> getKategoriByUser(int userId) async {
    final db = await database;
    return await db.query('kategori_transaksi',
        where: 'user_id = ?', whereArgs: [userId]);
  }

  //  BUDGET 
  Future<int> insertBudget(Map<String, dynamic> budget) async {
    final db = await database;
    return await db.insert('budget', budget);
  }

  Future<List<Map<String, dynamic>>> getBudgetByUser(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT b.*, k.nama as kategori_nama,
             COALESCE(SUM(t.jumlah), 0) as total_spent
      FROM budget b
      JOIN kategori_transaksi k ON b.kategori_id = k.id
      LEFT JOIN transaksi t ON t.kategori_id = b.kategori_id 
        AND t.user_id = b.user_id
        AND t.jenis = 'pengeluaran'
      WHERE b.user_id = ?
      GROUP BY b.id
    ''', [userId]);
  }

  Future<int> updateBudget(Map<String, dynamic> budget) async {
    final db = await database;
    return await db.update('budget', budget,
        where: 'id = ?', whereArgs: [budget['id']]);
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budget', where: 'id = ?', whereArgs: [id]);
  }

  // TABUNGAN 
  Future<int> insertTabungan(Map<String, dynamic> tabungan) async {
    final db = await database;
    return await db.insert('tabungan', tabungan);
  }

  Future<List<Map<String, dynamic>>> getTabunganByUser(int userId) async {
    final db = await database;
    return await db.query('tabungan',
        where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> updateTabungan(Map<String, dynamic> tabungan) async {
    final db = await database;
    return await db.update('tabungan', tabungan,
        where: 'id = ?', whereArgs: [tabungan['id']]);
  }

  Future<int> deleteTabungan(int id) async {
    final db = await database;
    return await db.delete('tabungan', where: 'id = ?', whereArgs: [id]);
  }

  //  LAPORAN 
  Future<List<Map<String, dynamic>>> getLaporanByPeriode(
      int userId, String dari, String sampai) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, k.nama as kategori_nama
      FROM transaksi t
      JOIN kategori_transaksi k ON t.kategori_id = k.id
      WHERE t.user_id = ? AND t.tanggal BETWEEN ? AND ?
      ORDER BY t.tanggal DESC
    ''', [userId, dari, sampai]);
  }

  Future<Map<String, dynamic>> getSummaryLaporan(
      int userId, String dari, String sampai) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN jenis = 'pemasukan' THEN jumlah ELSE 0 END) as total_pemasukan,
        SUM(CASE WHEN jenis = 'pengeluaran' THEN jumlah ELSE 0 END) as total_pengeluaran
      FROM transaksi
      WHERE user_id = ? AND tanggal BETWEEN ? AND ?
    ''', [userId, dari, sampai]);
    return result.first;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}