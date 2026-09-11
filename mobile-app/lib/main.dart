import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// DEEPCHECK-CHAIN
// "Sıfır Güven Dünyasında, Gerçeğin Sarsılmaz Zinciri"
//
// TEKNOFEST · Dijital Noter & Deepfake Dedektörü
// FastAPI + Hyperledger Fabric + AI (CNN/ViT)
// ═══════════════════════════════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Sistem UI overlay stilini ayarla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B132B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DeepCheckChainApp());
}

class DeepCheckChainApp extends StatelessWidget {
  const DeepCheckChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepCheck-Chain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}