import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/child_auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/companion_provider.dart';
import 'services/firebase_service.dart';
import 'services/pairing_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with fallback
  await FirebaseService.initialize();

  // Restore saved child pairing session from local storage
  await PairingService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChildAuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CompanionProvider()),
      ],
      child: const KidShieldChildApp(),
    ),
  );
}

class KidShieldChildApp extends StatelessWidget {
  const KidShieldChildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'KidShield Junior',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: child,
      ),
      child: const SplashScreen(),
    );
  }
}
