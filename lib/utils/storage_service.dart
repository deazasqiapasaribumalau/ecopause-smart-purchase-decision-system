// lib/utils/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _usersKey      = 'users';
  static const _currentUidKey = 'current_uid';
  static const _fomoKey       = 'fomo_evals';
  static const _wishlistKey   = 'wishlist';
  static const _logsKey       = 'shopping_logs';
  static const _notifKey      = 'notifications';

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
    if (idx != -1) { users[idx] = updated; await _saveUsers(users); }
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
    try { return users.firstWhere((u) => u.id == uid); } catch (_) { return null; }
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_currentUidKey);
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
    if (idx != -1) { all[idx] = updated; await _saveAllWishlist(all); }
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
    for (final n in all) { if (n.id == notifId) n.isRead = true; }
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
