// lib/models/models.dart
import 'dart:convert';

// ─── User ────────────────────────────────────────────────────────────────────
class AppUser {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final DateTime createdAt;
  bool notificationsEnabled;
  String? phone;
  String? bio;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    this.notificationsEnabled = true,
    this.phone,
    this.bio,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'createdAt': createdAt.toIso8601String(),
        'notificationsEnabled': notificationsEnabled,
        'phone': phone,
        'bio': bio,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        passwordHash: j['passwordHash'],
        createdAt: DateTime.parse(j['createdAt']),
        notificationsEnabled: j['notificationsEnabled'] ?? true,
        phone: j['phone'],
        bio: j['bio'],
      );
}

// ─── FOMO Evaluation ─────────────────────────────────────────────────────────
class FomoEvaluation {
  final String id;
  final String userId;
  final String itemName;
  final String category;
  final double price;
  final int needScore;
  final int fomoScore;
  final DateTime date;
  final String decision;
  final Map<String, bool> answers;
  final String? imagePath;

  FomoEvaluation({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.category,
    required this.price,
    required this.needScore,
    required this.fomoScore,
    required this.date,
    required this.decision,
    required this.answers,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'itemName': itemName,
        'category': category,
        'price': price,
        'needScore': needScore,
        'fomoScore': fomoScore,
        'date': date.toIso8601String(),
        'decision': decision,
        'answers': answers,
        'imagePath': imagePath,
      };

  factory FomoEvaluation.fromJson(Map<String, dynamic> j) => FomoEvaluation(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        itemName: j['itemName'] ?? '',
        category: j['category'] ?? '',
        price: (j['price'] ?? 0).toDouble(),
        needScore: j['needScore'] ?? 0,
        fomoScore: j['fomoScore'] ?? 0,
        date: DateTime.parse(j['date']),
        decision: j['decision'] ?? 'skip',
        answers: Map<String, bool>.from(j['answers'] ?? {}),
        imagePath: j['imagePath'],
      );
}

// ─── Wishlist Item ────────────────────────────────────────────────────────────
class WishlistItem {
  final String id;
  final String userId;
  final String itemName;
  final String category;
  final double price;
  final DateTime addedAt;
  final int coolingDays;
  final String? imagePath;
  bool isBought;
  bool isSkipped;
  bool notified;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.category,
    required this.price,
    required this.addedAt,
    required this.coolingDays,
    this.imagePath,
    this.isBought = false,
    this.isSkipped = false,
    this.notified = false,
  });

  DateTime get unlockAt => addedAt.add(Duration(days: coolingDays));
  bool get isUnlocked => DateTime.now().isAfter(unlockAt);
  bool get isPending => !isBought && !isSkipped;

  Duration get remainingCooling {
    final rem = unlockAt.difference(DateTime.now());
    return rem.isNegative ? Duration.zero : rem;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'itemName': itemName,
        'category': category,
        'price': price,
        'addedAt': addedAt.toIso8601String(),
        'coolingDays': coolingDays,
        'imagePath': imagePath,
        'isBought': isBought,
        'isSkipped': isSkipped,
        'notified': notified,
      };

  factory WishlistItem.fromJson(Map<String, dynamic> j) => WishlistItem(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        itemName: j['itemName'] ?? '',
        category: j['category'] ?? '',
        price: (j['price'] ?? 0).toDouble(),
        addedAt: DateTime.parse(j['addedAt']),
        coolingDays: j['coolingDays'] ?? 3,
        imagePath: j['imagePath'],
        isBought: j['isBought'] ?? false,
        isSkipped: j['isSkipped'] ?? false,
        notified: j['notified'] ?? false,
      );

  WishlistItem copyWith({
    String? id,
    String? userId,
    String? itemName,
    String? category,
    double? price,
    DateTime? addedAt,
    int? coolingDays,
    String? imagePath,
    bool? isBought,
    bool? isSkipped,
    bool? notified,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      price: price ?? this.price,
      addedAt: addedAt ?? this.addedAt,
      coolingDays: coolingDays ?? this.coolingDays,
      imagePath: imagePath ?? this.imagePath,
      isBought: isBought ?? this.isBought,
      isSkipped: isSkipped ?? this.isSkipped,
      notified: notified ?? this.notified,
    );
  }
}

// ─── Shopping Log ─────────────────────────────────────────────────────────────
class ShoppingLog {
  final String id;
  final String userId;
  final String itemName;
  final String category;
  final double price;
  final int packageCount;
  final bool isOnline;
  final DateTime date;
  final String deliveryType;
  final String? imagePath;

  ShoppingLog({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.category,
    required this.price,
    required this.packageCount,
    required this.isOnline,
    required this.date,
    this.deliveryType = 'regular',
    this.imagePath,
  });

  double get wasteKg => packageCount * 0.3;
  double get co2Emission => isOnline ? (deliveryType == 'sameday' ? 1.2 : 0.6) : 0.1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'itemName': itemName,
        'category': category,
        'price': price,
        'packageCount': packageCount,
        'isOnline': isOnline,
        'date': date.toIso8601String(),
        'deliveryType': deliveryType,
        'imagePath': imagePath,
      };

  factory ShoppingLog.fromJson(Map<String, dynamic> j) => ShoppingLog(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        itemName: j['itemName'] ?? '',
        category: j['category'] ?? '',
        price: (j['price'] ?? 0).toDouble(),
        packageCount: j['packageCount'] ?? 1,
        isOnline: j['isOnline'] ?? true,
        date: DateTime.parse(j['date']),
        deliveryType: j['deliveryType'] ?? 'regular',
        imagePath: j['imagePath'],
      );

  ShoppingLog copyWith({
    String? id,
    String? userId,
    String? itemName,
    String? category,
    double? price,
    int? packageCount,
    bool? isOnline,
    DateTime? date,
    String? deliveryType,
    String? imagePath,
  }) {
    return ShoppingLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      price: price ?? this.price,
      packageCount: packageCount ?? this.packageCount,
      isOnline: isOnline ?? this.isOnline,
      date: date ?? this.date,
      deliveryType: deliveryType ?? this.deliveryType,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

// ─── Notification ─────────────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'],
        userId: j['userId'],
        title: j['title'],
        body: j['body'],
        time: DateTime.parse(j['time']),
        isRead: j['isRead'] ?? false,
      );
}

// ─── Static Data ──────────────────────────────────────────────────────────────
const List<String> productCategories = [
  'Fashion & Pakaian',
  'Elektronik & Gadget',
  'Peralatan Rumah',
  'Makanan & Minuman',
  'Kecantikan & Skincare',
  'Olahraga & Outdoor',
  'Buku & Stationery',
  'Furnitur',
  'Mainan & Hobi',
  'Lainnya',
];

const Map<String, String> borrowSuggestions = {
  'Peralatan Rumah': '🔧 Alat seperti bor, tangga, atau mesin rumput lebih hemat jika dipinjam dari tetangga atau disewa.',
  'Elektronik & Gadget': '📷 Kamera, proyektor, atau drone bisa disewa di platform rental gadget.',
  'Olahraga & Outdoor': '⛺ Tenda, sleeping bag, dan perlengkapan camping bisa dipinjam dari komunitas outdoor.',
  'Buku & Stationery': '📚 Cek perpustakaan kampus atau iPusnas sebelum membeli buku baru!',
  'Furnitur': '🛋️ Furnitur besar lebih baik disewa untuk hunian sementara.',
};

const Map<String, List<String>> ecoAlternatives = {
  'Fashion & Pakaian': [
    '♻️ Thrift shop / pakaian preloved berkualitas',
    '🌿 Brand lokal berbahan organik atau daur ulang',
    '🔄 Platform tukar baju (swap clothing)',
    '✂️ Perbaiki & modifikasi pakaian lama',
  ],
  'Elektronik & Gadget': [
    '🔁 Beli refurbished / second hand terpercaya',
    '⚡ Produk bersertikat hemat energi (Energy Star)',
    '📦 Merek dengan kemasan daur ulang atau minimal',
  ],
  'Peralatan Rumah': [
    '🏘️ Pinjam dari tetangga / komunitas',
    '🛒 Pasar loak atau marketplace second hand',
    '🌱 Produk lokal berbahan ramah lingkungan',
  ],
  'Kecantikan & Skincare': [
    '🪴 Brand cruelty-free & vegan bersertifikat',
    '♻️ Produk dengan kemasan refill',
    '🌾 Bahan alami lokal (minyak kelapa, lidah buaya)',
  ],
  'Makanan & Minuman': [
    '🥬 Belanja di pasar tradisional tanpa plastik',
    '🛍️ Bawa tas & wadah sendiri',
    '🌾 Prioritaskan produk lokal & musiman',
  ],
  'Olahraga & Outdoor': [
    '♻️ Brand sportswear berbahan daur ulang',
    '🤝 Beli second hand dari komunitas olahraga',
    '🌿 Pilih produk dengan program take-back',
  ],
  'Buku & Stationery': [
    '📱 Versi e-book / digital',
    '📚 Pinjam di perpustakaan atau teman',
    '♻️ Stationery dari bahan daur ulang',
  ],
  'Lainnya': [
    '🔍 Cek marketplace second hand dulu',
    '♻️ Pilih produk kemasan minimal',
    '🌿 Prioritaskan brand lokal & berkelanjutan',
  ],
};