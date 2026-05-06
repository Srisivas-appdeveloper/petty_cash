import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // Note: Ensure you run `flutterfire configure` to generate firebase_options.dart
  // and import it if needed for specific platforms.
  bool isFirebaseInitialized = false;
  String? firebaseError;

  try {
    await Firebase.initializeApp();
    isFirebaseInitialized = true;
  } catch (e) {
    firebaseError = e.toString();
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF16213E),
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(PettyCashApp(
    isFirebaseInitialized: isFirebaseInitialized,
    firebaseError: firebaseError,
  ));
}

class AppColors {
  static const navy = Color(0xFF16213E);
  static const navyLight = Color(0xFF1A3A5C);
  static const green = Color(0xFF1E824C);
  static const red = Color(0xFFC0392B);
  static const grey = Color(0xFF7A8BA8);
  static const lightBg = Color(0xFFF0F3F8);
  static const cardBg = Colors.white;
  static const inputBg = Color(0xFFF8F9FC);
  static const inputBorder = Color(0xFFE4E9F2);
}

class PettyCashApp extends StatelessWidget {
  final bool isFirebaseInitialized;
  final String? firebaseError;

  const PettyCashApp({
    super.key,
    required this.isFirebaseInitialized,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFirebaseInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.lightBg,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase Not Configured',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The app is missing the Firebase configuration. You must run the following command in your terminal:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                    child: const Text('flutterfire configure', style: TextStyle(color: Colors.white, fontFamily: 'monospace')),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Original Error: $firebaseError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Petty Cash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.lightBg,
        colorSchemeSeed: AppColors.navy,
        fontFamily: 'DMSans',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.navy, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          margin: EdgeInsets.only(bottom: 16),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
