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
    final hash = _hashPassword(password);
    final user = await StorageService.getUserByEmail(email);
    if (user == null) return 'Email tidak terdaftar';
    if (user.passwordHash != hash) return 'Password salah';
    _user = user;
    await StorageService.setCurrentUser(user.id);
    await StorageService.checkWishlistUnlocks(user.id);
    notifyListeners();
    return null;
  }

  Future<String?> register(String name, String email, String password) async {
    if (name.trim().isEmpty) return 'Nama tidak boleh kosong';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) return 'Format email tidak valid';
    if (password.length < 6) return 'Password minimal 6 karakter';
    final existing = await StorageService.getUserByEmail(email);
    if (existing != null) return 'Email sudah terdaftar';
    final user = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(), 
      email: email.trim(),
      passwordHash: _hashPassword(password),
      createdAt: DateTime.now(),
    );
    await StorageService.registerUser(user);
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

  // ✅ PERBAIKI: Tambahkan phone dan bio
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? bio,
    bool? notificationsEnabled,
  }) async {
    if (_user == null) return;

    final updated = AppUser(
      id: _user!.id,
      name: name ?? _user!.name,
      email: email ?? _user!.email,
      passwordHash: _user!.passwordHash,
      createdAt: _user!.createdAt,
      notificationsEnabled: notificationsEnabled ?? _user!.notificationsEnabled,
      phone: phone ?? _user!.phone,
      bio: bio ?? _user!.bio,
    );
    
    await StorageService.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  String _hashPassword(String password) {
    // Simple hash using dart's built-in — in production use bcrypt
    var hash = 0;
    for (var i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash + password.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toString();
  }
}