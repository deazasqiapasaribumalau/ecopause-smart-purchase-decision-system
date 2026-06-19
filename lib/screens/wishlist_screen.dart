// lib/screens/wishlist_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
              _load();
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
              // Reset status item
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

  // Fungsi untuk kembali ke beranda
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
        title: const Text('⏳ Smart Wishlist'),
        backgroundColor: AppTheme.forest,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.cream),
          onPressed: _goToHome,
          tooltip: 'Kembali',
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
              label: '🏠 Kembali ke Beranda',
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
              // Tombol hapus (selalu muncul)
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
                  // Tombol untuk mengubah status (kembali ke pending)
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