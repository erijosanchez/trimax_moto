import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Barra de estado transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  await ApiService().init();
  await initBackgroundService();
  await NotificationService().init();

  runApp(const TrimaxMotoApp());
}

class TrimaxMotoApp extends StatelessWidget {
  const TrimaxMotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trimax Moto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a73e8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    final loggedIn = await AuthService().tryAutoLogin();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => loggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a2035),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Trimax Moto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cargando...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}