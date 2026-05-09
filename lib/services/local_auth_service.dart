import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class LocalAuthService {
  final db = DatabaseHelper.instance;

  // HASH FUNCTION
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // VALIDASI EMAIL
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  // REGISTER
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

  // LOGIN
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

  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Simpan profile image sebelum clear supaya tidak hilang
    final savedImage = prefs.getString('profile_image');
    await prefs.clear();
    // Kembalikan profile image kalau ada
    if (savedImage != null) {
      await prefs.setString('profile_image', savedImage);
    }
  }

  // CEK LOGIN
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // GET USER ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // SAVE PROFILE IMAGE PATH
  Future<void> saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      await prefs.setString('profile_image_$userId', path);
    }
  }

  // GET PROFILE IMAGE PATH
  Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return null;
    return prefs.getString('profile_image_$userId');
  }

  // DELETE PROFILE IMAGE
  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      await prefs.remove('profile_image_$userId');
    }
  }
}