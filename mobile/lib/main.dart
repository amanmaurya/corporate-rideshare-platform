import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const CorporateRideShareApp());
}

class CorporateRideShareApp extends StatelessWidget {
  const CorporateRideShareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corporate RideShare',
      theme: ThemeData(
        primarySwatch: MaterialColor(
          AppColors.primaryColor.value,
          <int, Color>{
            50: AppColors.primaryColor.withOpacity(0.1),
            100: AppColors.primaryColor.withOpacity(0.2),
            200: AppColors.primaryColor.withOpacity(0.3),
            300: AppColors.primaryColor.withOpacity(0.4),
            400: AppColors.primaryColor.withOpacity(0.5),
            500: AppColors.primaryColor,
            600: AppColors.primaryColor.withOpacity(0.7),
            700: AppColors.primaryColor.withOpacity(0.8),
            800: AppColors.primaryColor.withOpacity(0.9),
            900: AppColors.primaryColor.withOpacity(1.0),
          },
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        cardTheme: CardThemeData(
          color: AppColors.surfaceColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.surfaceColor,
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize authentication service
    await AuthService.initialize();

    // Add a small delay for splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Navigate to appropriate screen
    if (mounted) {
      if (AuthService.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'Corporate RideShare',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with your colleagues',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
