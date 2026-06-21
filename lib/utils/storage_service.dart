// lib/utils/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _usersKey      = 'users';
  static const _currentUidKey = 'current_uid';
  static const _fomoKey       = 'fomo_evals';
  static const _wishlistKey   = 'wishlist';
  static const _logsKey       = 'shopping_logs';
  static const _notifKey      = 'notifications';
  static const _profileImageKey = 'profile_image_';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<List<AppUser>> _loadUsers() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_usersKey) ?? [];
    return raw.map((e) => AppUser.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> _saveUsers(List<AppUser> users) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_usersKey, users.map((u) => jsonEncode(u.toJson())).toList());
  }

  static Future<AppUser?> getUserByEmail(String email) async {
    final users = await _loadUsers();
    try {
      return users.firstWhere((u) => u.email.toLowerCase() == email.toLowerCase());
    } catch (_) { return null; }
  }

  static Future<bool> registerUser(AppUser user) async {
    final existing = await getUserByEmail(user.email);
    if (existing != null) return false;
    final users = await _loadUsers();
    users.add(user);
    await _saveUsers(users);
    return true;
  }

  static Future<void> updateUser(AppUser updated) async {
    final users = await _loadUsers();
    final idx = users.indexWhere((u) => u.id == updated.id);
    if (idx != -1) { 
      users[idx] = updated; 
      await _saveUsers(users); 
    }
  }

  static Future<void> saveUser(AppUser user) async {
    final users = await _loadUsers();
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      users[idx] = user;
    } else {
      users.add(user);
    }
    await _saveUsers(users);
  }

  static Future<void> setCurrentUser(String uid) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_currentUidKey, uid);
  }

  static Future<AppUser?> getCurrentUser() async {
    final p = await SharedPreferences.getInstance();
    final uid = p.getString(_currentUidKey);
    if (uid == null) return null;
    final users = await _loadUsers();
    try { 
      return users.firstWhere((u) => u.id == uid); 
    } catch (_) { 
      return null; 
    }
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_currentUidKey);
  }

  // ── Profile Image ─────────────────────────────────────────────────────────
  static Future<String?> getProfileImage(String userId) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getString('$_profileImageKey$userId');
    } catch (e) {
      print('❌ Gagal get profile image: $e');
      return null;
    }
  }

  static Future<String?> saveProfileImage(String userId, File image) async {
    try {
      final p = await SharedPreferences.getInstance();
      
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/profile_images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final oldPath = p.getString('$_profileImageKey$userId');
      if (oldPath != null && oldPath.isNotEmpty) {
        try {
          final oldFile = File(oldPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (e) {
          print('⚠️ Gagal hapus gambar lama: $e');
        }
      }
      
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${imagesDir.path}/$fileName';
      final savedImage = await image.copy(savedPath);
      
      await p.setString('$_profileImageKey$userId', savedImage.path);
      print('✅ Profile image saved: ${savedImage.path}');
      return savedImage.path;
    } catch (e) {
      print('❌ Gagal save profile image: $e');
      return null;
    }
  }

  static Future<void> removeProfileImage(String userId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final path = p.getString('$_profileImageKey$userId');
      
      if (path != null && path.isNotEmpty) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            print('✅ Profile image deleted: $path');
          }
        } catch (e) {
          print('⚠️ Gagal hapus file profile image: $e');
        }
      }
      
      await p.remove('$_profileImageKey$userId');
    } catch (e) {
      print('❌ Gagal remove profile image: $e');
    }
  }

  // ── FOMO Evaluations ──────────────────────────────────────────────────────
  static Future<List<FomoEvaluation>> loadEvals(String userId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_fomoKey) ?? [];
    return raw
        .map((e) => FomoEvaluation.fromJson(jsonDecode(e)))
        .where((e) => e.userId == userId)
        .toList();
  }

  static Future<void> saveEval(FomoEvaluation eval) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_fomoKey) ?? [];
    list.add(jsonEncode(eval.toJson()));
    await p.setStringList(_fomoKey, list);
  }

  // ── Wishlist ──────────────────────────────────────────────────────────────
  static Future<List<WishlistItem>> loadWishlist(String userId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_wishlistKey) ?? [];
    return raw
        .map((e) => WishlistItem.fromJson(jsonDecode(e)))
        .where((e) => e.userId == userId)
        .toList();
  }

  static Future<void> _saveAllWishlist(List<WishlistItem> all) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_wishlistKey, all.map((e) => jsonEncode(e.toJson())).toList());
  }

  static Future<void> addToWishlist(WishlistItem item) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_wishlistKey) ?? [];
    final all = raw.map((e) => WishlistItem.fromJson(jsonDecode(e))).toList();
    all.add(item);
    await _saveAllWishlist(all);
    await addNotification(AppNotification(
      id: 'notif_${item.id}',
      userId: item.userId,
      title: '⏳ Ditambah ke Wishlist',
      body: '${item.itemName} akan siap dievaluasi dalam ${item.coolingDays} hari.',
      time: DateTime.now(),
    ));
  }

  static Future<void> updateWishlistItem(WishlistItem updated) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_wishlistKey) ?? [];
    final all = raw.map((e) => WishlistItem.fromJson(jsonDecode(e))).toList();
    final idx = all.indexWhere((i) => i.id == updated.id);
    if (idx != -1) { 
      all[idx] = updated; 
      await _saveAllWishlist(all); 
    }
  }

  static Future<void> deleteWishlistItem(String itemId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_wishlistKey) ?? [];
      final all = raw.map((e) => WishlistItem.fromJson(jsonDecode(e))).toList();
      
      final beforeCount = all.length;
      all.removeWhere((item) => item.id == itemId);
      
      if (all.length < beforeCount) {
        await _saveAllWishlist(all);
        print('✅ Item berhasil dihapus: $itemId');
      } else {
        print('⚠️ Item tidak ditemukan: $itemId');
      }
    } catch (e) {
      print('❌ Gagal menghapus item: $e');
      rethrow;
    }
  }

  // ── Shopping Logs ─────────────────────────────────────────────────────────
  static Future<List<ShoppingLog>> loadLogs(String userId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_logsKey) ?? [];
    return raw
        .map((e) => ShoppingLog.fromJson(jsonDecode(e)))
        .where((e) => e.userId == userId)
        .toList();
  }

  static Future<void> addLog(ShoppingLog log) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_logsKey) ?? [];
    list.add(jsonEncode(log.toJson()));
    await p.setStringList(_logsKey, list);
  }

  static Future<void> saveLog(ShoppingLog log) async {
    await addLog(log);
  }

  static Future<void> updateLog(ShoppingLog updatedLog) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_logsKey) ?? [];
      final all = raw.map((e) => ShoppingLog.fromJson(jsonDecode(e))).toList();
      final idx = all.indexWhere((l) => l.id == updatedLog.id);
      
      if (idx != -1) {
        all[idx] = updatedLog;
        await p.setStringList(_logsKey, all.map((e) => jsonEncode(e.toJson())).toList());
        print('✅ Log berhasil diupdate: ${updatedLog.id}');
      } else {
        print('⚠️ Log tidak ditemukan: ${updatedLog.id}');
      }
    } catch (e) {
      print('❌ Gagal mengupdate log: $e');
      rethrow;
    }
  }

  static Future<void> deleteLog(String logId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_logsKey) ?? [];
      final all = raw.map((e) => ShoppingLog.fromJson(jsonDecode(e))).toList();
      
      final beforeCount = all.length;
      all.removeWhere((l) => l.id == logId);
      
      if (all.length < beforeCount) {
        await p.setStringList(_logsKey, all.map((e) => jsonEncode(e.toJson())).toList());
        print('✅ Log berhasil dihapus: $logId');
      } else {
        print('⚠️ Log tidak ditemukan: $logId');
      }
    } catch (e) {
      print('❌ Gagal menghapus log: $e');
      rethrow;
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  static Future<List<AppNotification>> loadNotifications(String userId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_notifKey) ?? [];
    return raw
        .map((e) => AppNotification.fromJson(jsonDecode(e)))
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  static Future<void> addNotification(AppNotification notif) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_notifKey) ?? [];
    list.add(jsonEncode(notif.toJson()));
    await p.setStringList(_notifKey, list);
  }

  static Future<void> markNotifRead(String notifId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_notifKey) ?? [];
    final all = raw.map((e) => AppNotification.fromJson(jsonDecode(e))).toList();
    for (final n in all) { 
      if (n.id == notifId) n.isRead = true; 
    }
    await p.setStringList(_notifKey, all.map((e) => jsonEncode(e.toJson())).toList());
  }

  // ── Check wishlist unlocks and create notifications ────────────────────────
  static Future<void> checkWishlistUnlocks(String userId) async {
    final items = await loadWishlist(userId);
    for (final item in items) {
      if (item.isPending && item.isUnlocked && !item.notified) {
        item.notified = true;
        await updateWishlistItem(item);
        await addNotification(AppNotification(
          id: 'unlock_${item.id}',
          userId: userId,
          title: '✅ Cooling Period Selesai!',
          body: '"${item.itemName}" sudah bisa kamu putuskan — beli atau lewati?',
          time: DateTime.now(),
        ));
      }
    }
  }
}