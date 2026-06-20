// lib/screens/wishlist_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../utils/storage_service.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';

class WishlistScreen extends StatefulWidget {
  final AuthProvider auth;
  const WishlistScreen({super.key, required this.auth});
  @override State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with SingleTickerProviderStateMixin {
  List<WishlistItem> _items = [];
  bool _loading = true;
  late TabController _tab;

  @override
  void initState() { 
    super.initState(); 
    _tab = TabController(length: 3, vsync: this); 
    _load(); 
  }
  
  @override
  void dispose() { 
    _tab.dispose();
    super.dispose(); 
  }

  Future<void> _load() async {
    final uid = widget.auth.user!.id;
    await StorageService.checkWishlistUnlocks(uid);
    final items = await StorageService.loadWishlist(uid);
    if (mounted) {
      setState(() { 
        _items = items; 
        _loading = false; 
      });
    }
  }

  List<WishlistItem> get _cooling  => _items.where((i) => i.isPending && !i.isUnlocked).toList();
  List<WishlistItem> get _unlocked => _items.where((i) => i.isPending && i.isUnlocked).toList();
  List<WishlistItem> get _done     => _items.where((i) => i.isBought || i.isSkipped).toList();

  Future<void> _markBought(WishlistItem item) async { 
    item.isBought = true; 
    await StorageService.updateWishlistItem(item); 
    _load(); 
  }
  
  Future<void> _markSkipped(WishlistItem item) async { 
    item.isSkipped = true; 
    await StorageService.updateWishlistItem(item); 
    _load(); 
  }

  Future<void> _deleteItem(WishlistItem item) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Item?',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppTheme.forest,
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${item.itemName}" dari wishlist?',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppTheme.ink,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.nunito(color: AppTheme.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terra,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.deleteWishlistItem(item.id);
              setState(() {
                _items.removeWhere((i) => i.id == item.id);
              });
              await _load();
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppTheme.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetStatus(WishlistItem item) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ubah Status?',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppTheme.forest,
          ),
        ),
        content: Text(
          'Kembalikan item ke wishlist aktif?',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppTheme.ink,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.nunito(color: AppTheme.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              item.isBought = false;
              item.isSkipped = false;
              await StorageService.updateWishlistItem(item);
              _load();
            },
            child: Text(
              'Ya, Kembalikan',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppTheme.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWishlistForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddWishlistSheet(
        auth: widget.auth,
        onAdded: _load,
      ),
    );
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(auth: widget.auth),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Wishlist'),
        backgroundColor: AppTheme.forest,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.cream),
          onPressed: _goToHome,
          tooltip: 'Kembali',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.cream),
            onPressed: _showAddWishlistForm,
            tooltip: 'Tambah Wishlist',
          ),
        ],
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppTheme.cream,
        ),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.sage,
          indicatorWeight: 3,
          labelColor: AppTheme.cream,
          unselectedLabelColor: AppTheme.cream.withOpacity(0.5),
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 11),
          tabs: [
            Tab(text: '⏳ Cooling (${_cooling.length})'),
            Tab(text: '✨ Siap (${_unlocked.length})'),
            Tab(text: '✅ Selesai (${_done.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.sage))
          : TabBarView(
              controller: _tab,
              children: [
                _buildList(_cooling, 'cooling'),
                _buildList(_unlocked, 'unlocked'),
                _buildList(_done, 'done'),
              ],
            ),
    );
  }

  Widget _buildList(List<WishlistItem> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type == 'cooling' ? '🌱' 
                  : type == 'unlocked' ? '🎯' 
                  : '🏁',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              type == 'cooling' ? 'Tidak ada item dalam cooling period'
                  : type == 'unlocked' ? 'Tidak ada item yang siap diputuskan'
                  : 'Belum ada item selesai',
              style: GoogleFonts.nunito(
                color: AppTheme.grey, 
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'cooling' ? 'Item akan muncul di sini saat cooling period berjalan'
                  : type == 'unlocked' ? 'Item siap diputuskan akan muncul di sini'
                  : 'Item yang sudah dibeli atau dilewati akan muncul di sini',
              style: GoogleFonts.nunito(
                color: AppTheme.grey.withOpacity(0.6), 
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            EcoButton(
              label: 'Kembali ke Beranda',
              onTap: _goToHome,
              color: AppTheme.sage,
              icon: Icons.home_rounded,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _load, 
      color: AppTheme.sage,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) => _WishlistCard(
          item: items[i], 
          type: type, 
          onBuy: () => _markBought(items[i]), 
          onSkip: () => _markSkipped(items[i]),
          onDelete: () => _deleteItem(items[i]),
          onReset: () => _resetStatus(items[i]),
        ),
      ),
    );
  }
}

// ========== ADD WISHLIST SHEET ==========
class _AddWishlistSheet extends StatefulWidget {
  final AuthProvider auth;
  final VoidCallback onAdded;
  const _AddWishlistSheet({required this.auth, required this.onAdded});

  @override
  State<_AddWishlistSheet> createState() => _AddWishlistSheetState();
}

class _AddWishlistSheetState extends State<_AddWishlistSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = productCategories[0];
  int _coolingDays = 3;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tambah Foto',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forest,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ImageSourceBtn(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  _ImageSourceBtn(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                  if (_selectedImage != null)
                    _ImageSourceBtn(
                      icon: Icons.delete,
                      label: 'Hapus',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _removeImage();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveWishlist() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama barang!')),
      );
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan harga!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final item = WishlistItem(
        id: const Uuid().v4(),
        userId: widget.auth.user!.id,
        itemName: _nameCtrl.text.trim(),
        category: _category,
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        imagePath: _selectedImage?.path,
        addedAt: DateTime.now(),
        coolingDays: _coolingDays,
      );

      await StorageService.addToWishlist(item);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Item berhasil ditambahkan ke wishlist!'),
            backgroundColor: AppTheme.sage,
          ),
        );
        Navigator.pop(context);
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal menambahkan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '✏️ Tambah Wishlist',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forest,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.grey,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Nama Barang
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama Barang',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameCtrl,
                            style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.forest),
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama barang',
                              hintStyle: GoogleFonts.nunito(
                                fontSize: 14,
                                color: AppTheme.grey.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppTheme.sage, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.sage, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: true,
                              fillColor: AppTheme.bgLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Harga
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga (Rp)',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.forest),
                            decoration: InputDecoration(
                              hintText: 'Masukkan harga',
                              hintStyle: GoogleFonts.nunito(
                                fontSize: 14,
                                color: AppTheme.grey.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.sage, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.sage, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: true,
                              fillColor: AppTheme.bgLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Kategori
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kategori',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _category,
                            style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.forest),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.category_outlined, color: AppTheme.sage, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.sage, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: true,
                              fillColor: AppTheme.bgLight,
                            ),
                            items: productCategories.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: AppTheme.forest,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Cooling Period
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cooling Period',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [1, 3, 7].map((days) {
                              final isSelected = _coolingDays == days;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _coolingDays = days),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.sage : AppTheme.bgLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.sage : AppTheme.divider,
                                        width: isSelected ? 2 : 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$days hari',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? AppTheme.white : AppTheme.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Foto
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foto (Opsional)',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showImagePickerDialog,
                            child: Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.bgLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.divider, width: 1.5),
                              ),
                              child: _selectedImage != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            _selectedImage!,
                                            width: double.infinity,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: _removeImage,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 32,
                                          color: AppTheme.grey.withOpacity(0.6),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap untuk tambah foto',
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            color: AppTheme.grey.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading ? null : () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.grey, width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Batal',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading ? null : _saveWishlist,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.sage,
                                      AppTheme.forestMid,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.add_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Tambah',
                                            style: GoogleFonts.nunito(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ========== IMAGE SOURCE BUTTON ==========
class _ImageSourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ImageSourceBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? AppTheme.sage).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: color ?? AppTheme.sage,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== WISHLIST CARD ==========
class _WishlistCard extends StatelessWidget {
  final WishlistItem item; 
  final String type; 
  final VoidCallback onBuy, onSkip, onDelete, onReset;
  
  const _WishlistCard({
    required this.item, 
    required this.type, 
    required this.onBuy, 
    required this.onSkip,
    required this.onDelete,
    required this.onReset,
  });

  String _fmtDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}h ${d.inHours.remainder(24)}j lagi';
    if (d.inHours > 0) return '${d.inHours}j ${d.inMinutes.remainder(60)}m lagi';
    return '${d.inMinutes}m lagi';
  }
  
  String _fmt(double p) { 
    if (p >= 1e6) return '${(p/1e6).toStringAsFixed(1)} jt'; 
    if (p >= 1000) return '${(p/1000).toStringAsFixed(0)} rb'; 
    return p.toStringAsFixed(0); 
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.bgLight,
          child: const Icon(Icons.image_not_supported, size: 24, color: AppTheme.grey),
        ),
      );
    }
    
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.bgLight,
          child: const Icon(Icons.image_not_supported, size: 24, color: AppTheme.grey),
        ),
      );
    }
    
    return Container(
      color: AppTheme.bgLight,
      child: const Icon(Icons.image_not_supported, size: 24, color: AppTheme.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rem = item.remainingCooling;
    final progress = 1.0 - (rem.inSeconds / (item.coolingDays * 86400));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white, 
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: type == 'unlocked' 
              ? AppTheme.sage.withOpacity(0.6) 
              : AppTheme.divider, 
          width: type == 'unlocked' ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: type == 'unlocked' 
                ? AppTheme.sage.withOpacity(0.15) 
                : AppTheme.sage.withOpacity(0.06),
            blurRadius: type == 'unlocked' ? 12 : 8, 
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imagePath != null && item.imagePath!.isNotEmpty) ...[
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.divider, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageWidget(item.imagePath!),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName, 
                      style: GoogleFonts.nunito(
                        fontSize: 16, 
                        fontWeight: FontWeight.w800, 
                        color: AppTheme.forest,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        EcoChip(label: item.category),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.forestMid.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Rp ${_fmt(item.price)}', 
                            style: GoogleFonts.nunito(
                              fontSize: 11, 
                              fontWeight: FontWeight.w700, 
                              color: AppTheme.forestMid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.terra, size: 20),
                onPressed: onDelete,
                tooltip: 'Hapus',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              if (type == 'done') 
                EcoChip(
                  label: item.isBought ? '✅ Dibeli' : '⏭️ Dilewati', 
                  color: item.isBought ? AppTheme.sage : AppTheme.terra,
                ),
            ],
          ),
          
          if (type == 'cooling') ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text(
                  '⏳ ${_fmtDuration(rem)}', 
                  style: GoogleFonts.nunito(
                    fontSize: 12, 
                    fontWeight: FontWeight.w700, 
                    color: AppTheme.sand,
                  ),
                ),
                Text(
                  'Cooling ${item.coolingDays} hari', 
                  style: GoogleFonts.nunito(
                    fontSize: 11, 
                    color: AppTheme.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4), 
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0), 
                minHeight: 6,
                backgroundColor: AppTheme.bgLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.sand),
              ),
            ),
          ],
          
          if (type == 'unlocked') ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.sage.withOpacity(0.12),
                    AppTheme.sage.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.sage.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '✨',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cooling selesai! Apakah kamu masih mau membelinya?',
                      style: GoogleFonts.nunito(
                        fontSize: 12, 
                        color: AppTheme.forestMid, 
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onSkip, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.terra, width: 1.5), 
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Tidak Jadi', 
                        style: GoogleFonts.nunito(
                          fontSize: 13, 
                          fontWeight: FontWeight.w700, 
                          color: AppTheme.terra,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onBuy, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.sage,
                            AppTheme.forestMid,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Ya, Beli!', 
                        style: GoogleFonts.nunito(
                          fontSize: 13, 
                          fontWeight: FontWeight.w700, 
                          color: AppTheme.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          if (type == 'done') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    item.isBought ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: item.isBought ? AppTheme.sage : AppTheme.terra,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.isBought 
                          ? 'Item sudah dibeli ✅' 
                          : 'Item dilewati ⏭️',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onReset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.sage.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.sage.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Ubah Status',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.sage,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}