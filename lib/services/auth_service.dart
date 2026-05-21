import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  final _auth = FirebaseAuth.instance;

  // ── Ambil user yang sedang login ──────────────────────
  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  // ── Register ──────────────────────────────────────────
  Future<bool> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password.trim(),
      );
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password.trim(),
      );
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    // Simpan profile image, clear prefs sisanya
    final prefs = await SharedPreferences.getInstance();
    final uid = currentUserId;
    final savedImage = uid != null ? prefs.getString('profile_image_$uid') : null;
    await prefs.clear();
    if (savedImage != null && uid != null) {
      await prefs.setString('profile_image_$uid', savedImage);
    }
  }

  // ── Cek login ─────────────────────────────────────────
  bool isLoggedIn() => _auth.currentUser != null;

  // ── Get user ID (UID Firebase, bukan integer) ─────────
  String? getUserId() => _auth.currentUser?.uid;

  // ── Get user email ────────────────────────────────────
  String? getUserEmail() => _auth.currentUser?.email;

  // ── Update password ───────────────────────────────────
  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate dulu sebelum ganti password
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Profile image (tetap pakai SharedPreferences) ─────
  Future<void> saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = currentUserId;
    if (uid != null) await prefs.setString('profile_image_$uid', path);
  }

  Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = currentUserId;
    if (uid == null) return null;
    return prefs.getString('profile_image_$uid');
  }

  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = currentUserId;
    if (uid != null) await prefs.remove('profile_image_$uid');
  }
}