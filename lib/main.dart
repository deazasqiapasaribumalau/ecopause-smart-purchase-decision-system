// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/app_theme.dart';
import 'utils/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  runApp(const EcoPauseApp());
}

class EcoPauseApp extends StatelessWidget {
  const EcoPauseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'EcoPause',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    home: const _SplashGate(),
  );
}

// Checks for existing session — shows Login or Dashboard accordingly
class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final auth = AuthProvider();
    await auth.tryAutoLogin();
    if (!mounted) return;
    if (auth.isLoggedIn) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(auth: auth)));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.forest,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 88, height: 88,
        decoration: BoxDecoration(color: AppTheme.white.withOpacity(0.15), borderRadius: BorderRadius.circular(24)),
        child: const Center(child: Text('🌿', style: TextStyle(fontSize: 48)))),
      const SizedBox(height: 20),
      Text('EcoPause', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.cream, letterSpacing: 1,
        fontFamily: 'Nunito', decoration: TextDecoration.none)),
      const SizedBox(height: 32),
      const CircularProgressIndicator(color: AppTheme.sage, strokeWidth: 2),
    ])),
  );
}
