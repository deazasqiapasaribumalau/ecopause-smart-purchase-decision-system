// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final List<_OnboardData> _pages = const [
    _OnboardData(
      emoji: '🛍️',
      title: 'Belanja Lebih Bijak',
      subtitle:
          'EcoPause membantu kamu berpikir dua kali sebelum membeli — hemat uang, hemat emosi, hemat bumi.',
      bgColor: Color(0xFF1B4332),
      accentColor: Color(0xFF52B788),
    ),
    _OnboardData(
      emoji: '🧠',
      title: 'Deteksi FOMO Kamu',
      subtitle:
          'Tahu kapan kamu beli karena butuh, atau hanya karena takut ketinggalan. FOMO Detector kami bantu kamu sadar.',
      bgColor: Color(0xFF2D6A4F),
      accentColor: Color(0xFFB7E4C7),
    ),
    _OnboardData(
      emoji: '🌱',
      title: 'Jejak Belanja Hijau',
      subtitle:
          'Pantau riwayat keputusan belanjamu dan lihat seberapa besar kamu sudah berkontribusi ke gaya hidup berkelanjutan.',
      bgColor: Color(0xFF1B4332),
      accentColor: Color(0xFFE9C46A),
    ),
  ];

  Future<void> _done() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const _LandingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _done();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: page.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
                child: GestureDetector(
                  onTap: _done,
                  child: Text(
                    'Lewati',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: page.accentColor.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardPage(data: _pages[i]),
              ),
            ),

            // Bottom area
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Column(
                children: [
                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? page.accentColor
                              : page.accentColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Next / Mulai button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: page.accentColor,
                        foregroundColor: AppTheme.forest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Mulai Sekarang 🌿'
                            : 'Lanjut',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji illustration
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: data.accentColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(data.emoji, style: const TextStyle(fontSize: 64)),
            ),
          ),

          const SizedBox(height: 48),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.cream,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.cream.withOpacity(0.75),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Landing Screen (pilih Masuk / Daftar) ───────────────────────────────────

class _LandingScreen extends StatelessWidget {
  const _LandingScreen();

  PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position:
              Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOut),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.forest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.sage.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 52)),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'EcoPause',
                style: GoogleFonts.nunito(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.cream,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Think Before You Buy',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.sage,
                ),
              ),

              const Spacer(flex: 3),

              // Daftar button (primary)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .push(_slide(const RegisterScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sage,
                    foregroundColor: AppTheme.forest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Buat Akun Gratis',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Masuk button (secondary/outline)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).push(_slide(const LoginScreen())),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cream,
                    side: BorderSide(
                      color: AppTheme.cream.withOpacity(0.4),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Sudah Punya Akun? Masuk',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Gratis selamanya · Tanpa iklan · Data kamu aman',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppTheme.cream.withOpacity(0.4),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _OnboardData {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color accentColor;

  const _OnboardData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.accentColor,
  });
}
