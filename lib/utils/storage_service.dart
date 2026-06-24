// lib/utils/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _usersKey = 'users';
  static const _currentUidKey = 'current_uid';
  static const _fomoKey = 'fomo_evals';
  static const _wishlistKey = 'wishlist';
  static const _logsKey = 'shopping_logs';
  static const _notifKey = 'notifications';
  static const _profileImageKey = 'profile_image_';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<List<AppUser>> _loadUsers() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_usersKey) ?? [];
      return raw.map((e) => AppUser.fromJson(jsonDecode(e))).toList();
    } catch (e) {
      print('❌ Error loading users: $e');
      return [];
    }
  }

  static Future<void> _saveUsers(List<AppUser> users) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_usersKey, users.map((u) => jsonEncode(u.toJson())).toList());
      print('✅ Users saved: ${users.length} users');
    } catch (e) {
      print('❌ Error saving users: $e');
      rethrow;
    }
  }

  static Future<AppUser?> getUserByEmail(String email) async {
    try {
      print('🔍 Searching for user: $email');
      final users = await _loadUsers();
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );
      print('✅ User found: ${user.email}');
      return user;
    } catch (e) {
      print('❌ User not found: $email');
      return null;
    }
  }

  static Future<bool> registerUser(AppUser user) async {
    try {
      print('📝 Registering user: ${user.email}');
      
      // Cek apakah user sudah ada
      final existing = await getUserByEmail(user.email);
      if (existing != null) {
        print('⚠️ User already exists: ${user.email}');
        return false;
      }
      
      // Load users dan tambahkan user baru
      final users = await _loadUsers();
      users.add(user);
      await _saveUsers(users);
      
      print('✅ User registered successfully: ${user.email}');
      return true;
    } catch (e) {
      print('❌ Error registering user: $e');
      return false;
    }
  }

  static Future<void> updateUser(AppUser updated) async {
    try {
      print('📝 Updating user: ${updated.email}');
      final users = await _loadUsers();
      final idx = users.indexWhere((u) => u.id == updated.id);
      
      if (idx != -1) {
        users[idx] = updated;
        await _saveUsers(users);
        print('✅ User updated: ${updated.email}');
      } else {
        print('⚠️ User not found for update: ${updated.id}');
      }
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  static Future<void> saveUser(AppUser user) async {
    try {
      print('📝 Saving user: ${user.email}');
      final users = await _loadUsers();
      final idx = users.indexWhere((u) => u.id == user.id);
      
      if (idx != -1) {
        users[idx] = user;
      } else {
        users.add(user);
      }
      
      await _saveUsers(users);
      print('✅ User saved: ${user.email}');
    } catch (e) {
      print('❌ Error saving user: $e');
      rethrow;
    }
  }

  static Future<void> setCurrentUser(String uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_currentUidKey, uid);
      print('✅ Current user set: $uid');
    } catch (e) {
      print('❌ Error setting current user: $e');
      rethrow;
    }
  }

  static Future<AppUser?> getCurrentUser() async {
    try {
      final p = await SharedPreferences.getInstance();
      final uid = p.getString(_currentUidKey);
      
      if (uid == null) {
        print('ℹ️ No current user');
        return null;
      }
      
      final users = await _loadUsers();
      final user = users.firstWhere(
        (u) => u.id == uid,
        orElse: () => throw Exception('User not found'),
      );
      
      print('✅ Current user: ${user.email}');
      return user;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_currentUidKey);
      print('✅ User logged out');
    } catch (e) {
      print('❌ Error logging out: $e');
      rethrow;
    }
  }

  // ── Profile Image ─────────────────────────────────────────────────────────
  static Future<String?> getProfileImage(String userId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final path = p.getString('$_profileImageKey$userId');
      print('📸 Profile image path: $path');
      return path;
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
      print('✅ Profile image removed from preferences');
    } catch (e) {
      print('❌ Gagal remove profile image: $e');
    }
  }

  // ── FOMO Evaluations ──────────────────────────────────────────────────────
  static Future<List<FomoEvaluation>> loadEvals(String userId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_fomoKey) ?? [];
      return raw
          .map((e) => FomoEvaluation.fromJson(jsonDecode(e)))
          .where((e) => e.userId == userId)
          .toList();
    } catch (e) {
      print('❌ Error loading evaluations: $e');
      return [];
    }
  }

  static Future<void> saveEval(FomoEvaluation eval) async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = p.getStringList(_fomoKey) ?? [];
      list.add(jsonEncode(eval.toJson()));
      await p.setStringList(_fomoKey, list);
      print('✅ Evaluation saved: ${eval.id}');
    } catch (e) {
      print('❌ Error saving evaluation: $e');
      rethrow;
    }
  }

  // ── Wishlist ──────────────────────────────────────────────────────────────
  static Future<List<WishlistItem>> loadWishlist(String userId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_wishlistKey) ?? [];
      return raw
          .map((e) => WishlistItem.fromJson(jsonDecode(e)))
          .where((e) => e.userId == userId)
          .toList();
    } catch (e) {
      print('❌ Error loading wishlist: $e');
      return [];
    }
  }

  static Future<void> _saveAllWishlist(List<WishlistItem> all) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_wishlistKey, all.map((e) => jsonEncode(e.toJson())).toList());
      print('✅ Wishlist saved: ${all.length} items');
    } catch (e) {
      print('❌ Error saving wishlist: $e');
      rethrow;
    }
  }

  static Future<void> addToWishlist(WishlistItem item) async {
    try {
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
      print('✅ Item added to wishlist: ${item.itemName}');
    } catch (e) {
      print('❌ Error adding to wishlist: $e');
      rethrow;
    }
  }

  static Future<void> updateWishlistItem(WishlistItem updated) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_wishlistKey) ?? [];
      final all = raw.map((e) => WishlistItem.fromJson(jsonDecode(e))).toList();
      final idx = all.indexWhere((i) => i.id == updated.id);
      
      if (idx != -1) {
        all[idx] = updated;
        await _saveAllWishlist(all);
        print('✅ Wishlist item updated: ${updated.id}');
      } else {
        print('⚠️ Wishlist item not found: ${updated.id}');
      }
    } catch (e) {
      print('❌ Error updating wishlist item: $e');
      rethrow;
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
        print('✅ Wishlist item deleted: $itemId');
      } else {
        print('⚠️ Wishlist item not found: $itemId');
      }
    } catch (e) {
      print('❌ Error deleting wishlist item: $e');
      rethrow;
    }
  }

  // ── Shopping Logs ─────────────────────────────────────────────────────────
  static Future<List<ShoppingLog>> loadLogs(String userId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_logsKey) ?? [];
      return raw
          .map((e) => ShoppingLog.fromJson(jsonDecode(e)))
          .where((e) => e.userId == userId)
          .toList();
    } catch (e) {
      print('❌ Error loading logs: $e');
      return [];
    }
  }

  static Future<void> addLog(ShoppingLog log) async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = p.getStringList(_logsKey) ?? [];
      list.add(jsonEncode(log.toJson()));
      await p.setStringList(_logsKey, list);
      print('✅ Log added: ${log.itemName}');
    } catch (e) {
      print('❌ Error adding log: $e');
      rethrow;
    }
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
        print('✅ Log updated: ${updatedLog.id}');
      } else {
        print('⚠️ Log not found: ${updatedLog.id}');
      }
    } catch (e) {
      print('❌ Error updating log: $e');
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
        print('✅ Log deleted: $logId');
      } else {
        print('⚠️ Log not found: $logId');
      }
    } catch (e) {
      print('❌ Error deleting log: $e');
      rethrow;
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  static Future<List<AppNotification>> loadNotifications(String userId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_notifKey) ?? [];
      return raw
          .map((e) => AppNotification.fromJson(jsonDecode(e)))
          .where((e) => e.userId == userId)
          .toList()
        ..sort((a, b) => b.time.compareTo(a.time));
    } catch (e) {
      print('❌ Error loading notifications: $e');
      return [];
    }
  }

  static Future<void> addNotification(AppNotification notif) async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = p.getStringList(_notifKey) ?? [];
      list.add(jsonEncode(notif.toJson()));
      await p.setStringList(_notifKey, list);
      print('✅ Notification added: ${notif.title}');
    } catch (e) {
      print('❌ Error adding notification: $e');
      rethrow;
    }
  }

  static Future<void> markNotifRead(String notifId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_notifKey) ?? [];
      final all = raw.map((e) => AppNotification.fromJson(jsonDecode(e))).toList();
      
      for (final n in all) {
        if (n.id == notifId) n.isRead = true;
      }
      
      await p.setStringList(_notifKey, all.map((e) => jsonEncode(e.toJson())).toList());
      print('✅ Notification marked as read: $notifId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  // ── Check wishlist unlocks and create notifications ────────────────────────
  static Future<void> checkWishlistUnlocks(String userId) async {
    try {
      final items = await loadWishlist(userId);
      int unlockedCount = 0;
      
      for (final item in items) {
        if (item.isPending && item.isUnlocked && !item.notified) {
          final updatedItem = item.copyWith(notified: true);
          await updateWishlistItem(updatedItem);
          await addNotification(AppNotification(
            id: 'unlock_${item.id}',
            userId: userId,
            title: '✅ Cooling Period Selesai!',
            body: '"${item.itemName}" sudah bisa kamu putuskan — beli atau lewati?',
            time: DateTime.now(),
          ));
          unlockedCount++;
        }
      }
      
      if (unlockedCount > 0) {
        print('✅ $unlockedCount wishlist items unlocked');
      }
    } catch (e) {
      print('❌ Error checking wishlist unlocks: $e');
    }
  }

  // ── Utility: Debug ──────────────────────────────────────────────────────────
  static Future<void> printAllUsers() async {
    try {
      final users = await _loadUsers();
      print('📊 Total users: ${users.length}');
      for (final user in users) {
        print('  - ${user.email} (${user.name})');
      }
    } catch (e) {
      print('❌ Error printing users: $e');
    }
  }

  // ── Utility: Clear all data ──────────────────────────────────────────────
  static Future<void> clearAllData() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_usersKey);
      await p.remove(_currentUidKey);
      await p.remove(_fomoKey);
      await p.remove(_wishlistKey);
      await p.remove(_logsKey);
      await p.remove(_notifKey);
      
      // Hapus folder profile images
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDir.path}/profile_images');
        if (await imagesDir.exists()) {
          await imagesDir.delete(recursive: true);
        }
      } catch (e) {
        print('⚠️ Error deleting profile images: $e');
      }
      
      print('🗑️ All data cleared');
    } catch (e) {
      print('❌ Error clearing all data: $e');
      rethrow;
    }
  }
}