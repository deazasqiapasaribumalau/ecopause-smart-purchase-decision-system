// lib/utils/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'storage_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> tryAutoLogin() async {
    _user = await StorageService.getCurrentUser();
    if (_user != null) {
      await StorageService.checkWishlistUnlocks(_user!.id);
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    if (email.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (password.trim().isEmpty) {
      return 'Password tidak boleh kosong';
    }

    final hash = _hashPassword(password);
    final user = await StorageService.getUserByEmail(email.trim());

    if (user == null) {
      return 'Email tidak terdaftar';
    }
    if (user.passwordHash != hash) {
      return 'Password salah';
    }

    _user = user;
    await StorageService.setCurrentUser(user.id);
    await StorageService.checkWishlistUnlocks(user.id);
    notifyListeners();

    return null;
  }

  Future<String?> register(String name, String email, String password) async {
    final nameTrim = name.trim();
    final emailTrim = email.trim();
    final passTrim = password.trim();

    if (nameTrim.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailTrim)) {
      return 'Format email tidak valid';
    }
    if (passTrim.length < 6) {
      return 'Password minimal 6 karakter';
    }

    final existing = await StorageService.getUserByEmail(emailTrim);
    if (existing != null) {
      return 'Email sudah terdaftar';
    }

    final user = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: nameTrim,
      email: emailTrim,
      passwordHash: _hashPassword(passTrim),
      createdAt: DateTime.now(),
    );

    final success = await StorageService.registerUser(user);
    if (!success) {
      return 'Gagal mendaftar, silakan coba lagi';
    }

    _user = user;
    await StorageService.setCurrentUser(user.id);
    notifyListeners();

    return null;
  }

  Future<void> logout() async {
    await StorageService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? bio,
    bool? notificationsEnabled,
  }) async {
    if (_user == null) {
      throw Exception('User tidak ditemukan');
    }

    // ✅ Validasi nama tidak boleh kosong
    if (name != null && name.trim().isEmpty) {
      throw Exception('Nama tidak boleh kosong');
    }

    // ✅ Validasi email
    if (email != null && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
      throw Exception('Format email tidak valid');
    }

    final updated = AppUser(
      id: _user!.id,
      name: name?.trim() ?? _user!.name,
      email: email?.trim() ?? _user!.email,
      passwordHash: _user!.passwordHash,
      createdAt: _user!.createdAt,
      notificationsEnabled: notificationsEnabled ?? _user!.notificationsEnabled,
      phone: phone != null && phone.trim().isNotEmpty ? phone.trim() : _user!.phone,
      bio: bio != null && bio.trim().isNotEmpty ? bio.trim() : _user!.bio,
    );

    await StorageService.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  // ✅ Tambahkan fungsi untuk reload user (berguna setelah update)
  Future<void> refreshUser() async {
    if (_user == null) return;
    final updatedUser = await StorageService.getUserByEmail(_user!.email);
    if (updatedUser != null) {
      _user = updatedUser;
      notifyListeners();
    }
  }

  String _hashPassword(String password) {
    // Simple hash untuk development
    var hash = 0;
    for (var i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash + password.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toString();
  }
}