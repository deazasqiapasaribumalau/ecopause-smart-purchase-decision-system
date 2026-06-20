// lib/database/database_helper.dart
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'ecopause.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel Users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        notificationsEnabled INTEGER DEFAULT 1,
        phone TEXT,
        bio TEXT
      )
    ''');

    // Tabel FOMO Evaluations
    await db.execute('''
      CREATE TABLE evaluations (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        itemName TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        needScore INTEGER NOT NULL,
        fomoScore INTEGER NOT NULL,
        date TEXT NOT NULL,
        decision TEXT NOT NULL,
        answers TEXT NOT NULL,
        imagePath TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabel Wishlist
    await db.execute('''
      CREATE TABLE wishlist (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        itemName TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        addedAt TEXT NOT NULL,
        coolingDays INTEGER NOT NULL,
        imagePath TEXT,
        isBought INTEGER DEFAULT 0,
        isSkipped INTEGER DEFAULT 0,
        notified INTEGER DEFAULT 0,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabel Shopping Logs
    await db.execute('''
      CREATE TABLE shopping_logs (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        itemName TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        packageCount INTEGER NOT NULL,
        isOnline INTEGER NOT NULL,
        date TEXT NOT NULL,
        deliveryType TEXT NOT NULL,
        imagePath TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabel Notifications
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        time TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Index untuk performa
    await db.execute('CREATE INDEX idx_evaluations_userId ON evaluations(userId)');
    await db.execute('CREATE INDEX idx_wishlist_userId ON wishlist(userId)');
    await db.execute('CREATE INDEX idx_shopping_logs_userId ON shopping_logs(userId)');
    await db.execute('CREATE INDEX idx_notifications_userId ON notifications(userId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN bio TEXT');
      } catch (e) {
        print('Migration error: $e');
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE shopping_logs ADD COLUMN imagePath TEXT');
      } catch (e) {
        print('Migration error: $e');
      }
    }
  }

  // ─── Helper untuk clear database ──────────────────────────────────────────
  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete('users');
    await db.delete('evaluations');
    await db.delete('wishlist');
    await db.delete('shopping_logs');
    await db.delete('notifications');
  }
}

// ─── DAO: Users ──────────────────────────────────────────────────────────────
class UserDao {
  final Database db;

  UserDao(this.db);

  Future<List<AppUser>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((map) => _userFromMap(map)).toList();
  }

  Future<AppUser?> getByEmail(String email) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (maps.isEmpty) return null;
    return _userFromMap(maps.first);
  }

  Future<AppUser?> getById(String id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _userFromMap(maps.first);
  }

  Future<void> insert(AppUser user) async {
    await db.insert('users', _userToMap(user));
  }

  Future<void> update(AppUser user) async {
    await db.update(
      'users',
      _userToMap(user),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  AppUser _userFromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      passwordHash: map['passwordHash'],
      createdAt: DateTime.parse(map['createdAt']),
      notificationsEnabled: map['notificationsEnabled'] == 1,
      phone: map['phone'],
      bio: map['bio'],
    );
  }

  Map<String, dynamic> _userToMap(AppUser user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'passwordHash': user.passwordHash,
      'createdAt': user.createdAt.toIso8601String(),
      'notificationsEnabled': user.notificationsEnabled ? 1 : 0,
      'phone': user.phone,
      'bio': user.bio,
    };
  }
}

// ─── DAO: Evaluations ────────────────────────────────────────────────────────
class EvaluationDao {
  final Database db;

  EvaluationDao(this.db);

  Future<List<FomoEvaluation>> getByUserId(String userId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'evaluations',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => _evaluationFromMap(map)).toList();
  }

  Future<void> insert(FomoEvaluation eval) async {
    await db.insert('evaluations', _evaluationToMap(eval));
  }

  Future<void> delete(String id) async {
    await db.delete(
      'evaluations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  FomoEvaluation _evaluationFromMap(Map<String, dynamic> map) {
    return FomoEvaluation(
      id: map['id'],
      userId: map['userId'],
      itemName: map['itemName'],
      category: map['category'],
      price: map['price'],
      needScore: map['needScore'],
      fomoScore: map['fomoScore'],
      date: DateTime.parse(map['date']),
      decision: map['decision'],
      answers: Map<String, bool>.from(jsonDecode(map['answers'])),
      imagePath: map['imagePath'],
    );
  }

  Map<String, dynamic> _evaluationToMap(FomoEvaluation eval) {
    return {
      'id': eval.id,
      'userId': eval.userId,
      'itemName': eval.itemName,
      'category': eval.category,
      'price': eval.price,
      'needScore': eval.needScore,
      'fomoScore': eval.fomoScore,
      'date': eval.date.toIso8601String(),
      'decision': eval.decision,
      'answers': jsonEncode(eval.answers),
      'imagePath': eval.imagePath,
    };
  }
}

// ─── DAO: Wishlist ───────────────────────────────────────────────────────────
class WishlistDao {
  final Database db;

  WishlistDao(this.db);

  Future<List<WishlistItem>> getByUserId(String userId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'wishlist',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'addedAt DESC',
    );
    return maps.map((map) => _wishlistFromMap(map)).toList();
  }

  Future<void> insert(WishlistItem item) async {
    await db.insert('wishlist', _wishlistToMap(item));
  }

  Future<void> update(WishlistItem item) async {
    await db.update(
      'wishlist',
      _wishlistToMap(item),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete(
      'wishlist',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  WishlistItem _wishlistFromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'],
      userId: map['userId'],
      itemName: map['itemName'],
      category: map['category'],
      price: map['price'],
      addedAt: DateTime.parse(map['addedAt']),
      coolingDays: map['coolingDays'],
      imagePath: map['imagePath'],
      isBought: map['isBought'] == 1,
      isSkipped: map['isSkipped'] == 1,
      notified: map['notified'] == 1,
    );
  }

  Map<String, dynamic> _wishlistToMap(WishlistItem item) {
    return {
      'id': item.id,
      'userId': item.userId,
      'itemName': item.itemName,
      'category': item.category,
      'price': item.price,
      'addedAt': item.addedAt.toIso8601String(),
      'coolingDays': item.coolingDays,
      'imagePath': item.imagePath,
      'isBought': item.isBought ? 1 : 0,
      'isSkipped': item.isSkipped ? 1 : 0,
      'notified': item.notified ? 1 : 0,
    };
  }
}

// ─── DAO: Shopping Logs ──────────────────────────────────────────────────────
class ShoppingLogDao {
  final Database db;

  ShoppingLogDao(this.db);

  Future<List<ShoppingLog>> getByUserId(String userId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_logs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => _logFromMap(map)).toList();
  }

  Future<void> insert(ShoppingLog log) async {
    await db.insert('shopping_logs', _logToMap(log));
  }

  Future<void> update(ShoppingLog log) async {
    await db.update(
      'shopping_logs',
      _logToMap(log),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete(
      'shopping_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  ShoppingLog _logFromMap(Map<String, dynamic> map) {
    return ShoppingLog(
      id: map['id'],
      userId: map['userId'],
      itemName: map['itemName'],
      category: map['category'],
      price: map['price'],
      packageCount: map['packageCount'],
      isOnline: map['isOnline'] == 1,
      date: DateTime.parse(map['date']),
      deliveryType: map['deliveryType'],
      imagePath: map['imagePath'],
    );
  }

  Map<String, dynamic> _logToMap(ShoppingLog log) {
    return {
      'id': log.id,
      'userId': log.userId,
      'itemName': log.itemName,
      'category': log.category,
      'price': log.price,
      'packageCount': log.packageCount,
      'isOnline': log.isOnline ? 1 : 0,
      'date': log.date.toIso8601String(),
      'deliveryType': log.deliveryType,
      'imagePath': log.imagePath,
    };
  }
}

// ─── DAO: Notifications ─────────────────────────────────────────────────────
class NotificationDao {
  final Database db;

  NotificationDao(this.db);

  Future<List<AppNotification>> getByUserId(String userId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'time DESC',
    );
    return maps.map((map) => _notificationFromMap(map)).toList();
  }

  Future<void> insert(AppNotification notif) async {
    await db.insert('notifications', _notificationToMap(notif));
  }

  Future<void> markRead(String id) async {
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllRead(String userId) async {
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'userId = ? AND isRead = 0',
      whereArgs: [userId],
    );
  }

  AppNotification _notificationFromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      body: map['body'],
      time: DateTime.parse(map['time']),
      isRead: map['isRead'] == 1,
    );
  }

  Map<String, dynamic> _notificationToMap(AppNotification notif) {
    return {
      'id': notif.id,
      'userId': notif.userId,
      'title': notif.title,
      'body': notif.body,
      'time': notif.time.toIso8601String(),
      'isRead': notif.isRead ? 1 : 0,
    };
  }
}