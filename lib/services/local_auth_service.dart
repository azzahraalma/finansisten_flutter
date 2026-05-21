import 'dart:convert';

import 'auth_service.dart';

class LocalAuthService {
  final _auth = AuthService.instance;

  Future<bool> isLoggedIn() async {
    return _auth.isLoggedIn();
  }

  Future<String?> getUserId() async {
    return _auth.getUserId();
  }

  Future<void> logout() async {
    await _auth.logout();
  }

  Future<void> saveProfileImage(String path) async {
    await _auth.saveProfileImage(path);
  }

  Future<String?> getProfileImage() async {
    return _auth.getProfileImage();
  }

  Future<void> deleteProfileImage() async {
    await _auth.deleteProfileImage();
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password.trim());
    return base64Url.encode(bytes);
  }
}
