import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class LocalAuthService {
  final db = DatabaseHelper.instance;

  // ================= HASH FUNCTION =================
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ================= VALIDASI EMAIL =================
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  // ================= REGISTER =================
  Future<bool> register(String email, String password) async {
    try {
      email = email.toLowerCase().trim();

      if (!isValidEmail(email)) return false;
      if (password.length < 6) return false;

      final existing = await db.getUserByEmail(email);
      if (existing != null) return false;

      final hashedPassword = hashPassword(password);

      await db.insertUser({
        'email': email,
        'username': email.split('@')[0],
        'password': hashedPassword,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ================= LOGIN =================
  Future<bool> login(String email, String password) async {
    try {
      email = email.toLowerCase().trim();

      final user = await db.getUserByEmail(email);
      if (user == null) return false;

      final hashedInput = hashPassword(password);

      if (user['password'] != hashedInput) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user['id']);
      await prefs.setString('user_email', user['email']);
      await prefs.setBool('is_logged_in', true);

      return true;
    } catch (e) {
      return false;
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ================= CEK LOGIN =================
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // ================= GET USER ID =================
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }
}