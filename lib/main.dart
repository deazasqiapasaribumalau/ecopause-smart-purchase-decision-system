// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Cek dan reset onboarding jika diperlukan (opsional)
  // Hapus comment jika ingin reset otomatis
  // await _checkOnboardingStatus();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const EcoPauseApp(),
    ),
  );
}

// Fungsi opsional untuk cek onboarding
Future<void> _checkOnboardingStatus() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('onboarding_done') ?? false;
    print('📊 Onboarding status: $hasSeen');
    
    // Jika ingin reset otomatis (untuk testing)
    // await prefs.remove('onboarding_done');
    // print('🗑️ Onboarding direset!');
  } catch (e) {
    print('❌ Error checking onboarding: $e');
  }
}

class EcoPauseApp extends StatelessWidget {
  const EcoPauseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoPause',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: const SplashScreen(),
    );
  }
}