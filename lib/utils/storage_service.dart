// lib/utils/storage_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

class StorageService {
  static const _currentUidKey = 'current_uid';
  static const _profileImageKey = 'profile_image_';

  static DatabaseHelper get _db => DatabaseHelper();

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<AppUser?> getUserByEmail(String email) async {
    final db = await _db.database;
    return await UserDao(db).getByEmail(email);
  }

  static Future<bool> registerUser(AppUser user) async {
    final existing = await getUserByEmail(user.email);
    if (existing != null) return false;
    final db = await _db.database;
    await UserDao(db).insert(user);
    return true;
  }

  static Future<void> updateUser(AppUser updated) async {
    final db = await _db.database;
    await UserDao(db).update(updated);
  }

  static Future<void> saveUser(AppUser user) async {
    final db = await _db.database;
    await UserDao(db).insert(user);
  }

  static Future<void> setCurrentUser(String uid) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_currentUidKey, uid);
  }

  static Future<AppUser?> getCurrentUser() async {
    final p = await SharedPreferences.getInstance();
    final uid = p.getString(_currentUidKey);
    if (uid == null) return null;
    final db = await _db.database;
    return await UserDao(db).getById(uid);
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
    final db = await _db.database;
    return await EvaluationDao(db).getByUserId(userId);
  }

  static Future<void> saveEval(FomoEvaluation eval) async {
    final db = await _db.database;
    await EvaluationDao(db).insert(eval);
  }

  // ── Wishlist ──────────────────────────────────────────────────────────────

  static Future<List<WishlistItem>> loadWishlist(String userId) async {
    final db = await _db.database;
    return await WishlistDao(db).getByUserId(userId);
  }

  static Future<void> addToWishlist(WishlistItem item) async {
    final db = await _db.database;
    await WishlistDao(db).insert(item);
    await addNotification(AppNotification(
      id: 'notif_${item.id}',
      userId: item.userId,
      title: '⏳ Ditambah ke Wishlist',
      body: '${item.itemName} akan siap dievaluasi dalam ${item.coolingDays} hari.',
      time: DateTime.now(),
    ));
  }

  static Future<void> updateWishlistItem(WishlistItem updated) async {
    final db = await _db.database;
    await WishlistDao(db).update(updated);
  }

  static Future<void> deleteWishlistItem(String itemId) async {
    try {
      final db = await _db.database;
      await WishlistDao(db).delete(itemId);
      print('✅ Item berhasil dihapus: $itemId');
    } catch (e) {
      print('❌ Gagal menghapus item: $e');
      rethrow;
    }
  }

  // ── Shopping Logs ─────────────────────────────────────────────────────────

  static Future<List<ShoppingLog>> loadLogs(String userId) async {
    final db = await _db.database;
    return await ShoppingLogDao(db).getByUserId(userId);
  }

  static Future<void> addLog(ShoppingLog log) async {
    final db = await _db.database;
    await ShoppingLogDao(db).insert(log);
  }

  static Future<void> saveLog(ShoppingLog log) async {
    await addLog(log);
  }

  static Future<void> updateLog(ShoppingLog updatedLog) async {
    try {
      final db = await _db.database;
      await ShoppingLogDao(db).update(updatedLog);
      print('✅ Log berhasil diupdate: ${updatedLog.id}');
    } catch (e) {
      print('❌ Gagal mengupdate log: $e');
      rethrow;
    }
  }

  static Future<void> deleteLog(String logId) async {
    try {
      final db = await _db.database;
      await ShoppingLogDao(db).delete(logId);
      print('✅ Log berhasil dihapus: $logId');
    } catch (e) {
      print('❌ Gagal menghapus log: $e');
      rethrow;
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static Future<List<AppNotification>> loadNotifications(String userId) async {
    final db = await _db.database;
    return await NotificationDao(db).getByUserId(userId);
  }

  static Future<void> addNotification(AppNotification notif) async {
    final db = await _db.database;
    await NotificationDao(db).insert(notif);
  }

  static Future<void> markNotifRead(String notifId) async {
    final db = await _db.database;
    await NotificationDao(db).markRead(notifId);
  }

  static Future<void> markAllNotifRead(String userId) async {
    final db = await _db.database;
    await NotificationDao(db).markAllRead(userId);
  }

  // ── Check wishlist unlocks and create notifications ─────────────────────

  static Future<void> checkWishlistUnlocks(String userId) async {
    final items = await loadWishlist(userId);
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
      }
    }
  }

  // ── Utility: Clear all data ──────────────────────────────────────────────

  static Future<void> clearAllData() async {
    final db = await _db.database;
    await db.delete('users');
    await db.delete('evaluations');
    await db.delete('wishlist');
    await db.delete('shopping_logs');
    await db.delete('notifications');
    await logout();
    print('🗑️ All data cleared');
  }
}