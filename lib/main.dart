import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/local_auth_service.dart';
import 'config/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/food_scan_provider.dart';
import 'providers/gamification_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/profile_onboarding_screen.dart';
import 'screens/scan/scan_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FoodScanProvider(dotenv.env['GEMINI_API_KEY'] ?? '')),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ],
      child: MaterialApp(
        title: 'FoodWise',
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryColor,
            secondary: AppColors.secondaryColor,
            surface: AppColors.surfaceColor,
            background: AppColors.backgroundColor,
            error: AppColors.errorColor,
          ),
          scaffoldBackgroundColor: AppColors.backgroundColor,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.textLight,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
            ),
          ),
          cardTheme: CardTheme(
            color: AppColors.surfaceColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.textLight,
            elevation: 4,
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            titleMedium: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: TextStyle(color: AppColors.textPrimary),
            bodyMedium: TextStyle(color: AppColors.textSecondary),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.surfaceColor,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: AppColors.textSecondary,
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        locale: const Locale('id', 'ID'),
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/profile': (context) => const ProfileOnboardingScreen(),
          '/scan': (context) => const ScanScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingLocalAuth = true;
  bool _isLocallyLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLocalAuthStatus();
  }

  Future<void> _checkLocalAuthStatus() async {
    try {
      // Periksa status login dari penyimpanan lokal
      final isLoggedIn = await LocalAuthService.isLoggedIn();
      
      if (mounted) {
        setState(() {
          _isLocallyLoggedIn = isLoggedIn;
          _isCheckingLocalAuth = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error checking local auth status: $e');
      if (mounted) {
        setState(() {
          _isCheckingLocalAuth = false;
        });
      }
    }
  }

  bool _isProfileComplete(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      // Return false jika user null
      if (user == null) {
        print('DEBUG: User is null in _isProfileComplete');
        return false;
      }
      
      // Cek apakah profil pengguna lengkap
      final isComplete = user.isProfileComplete;
      print('DEBUG: Profile complete status: $isComplete');
      return isComplete;
    } catch (e) {
      print('DEBUG: Error in _isProfileComplete: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika masih memeriksa status login lokal, tampilkan loading
    if (_isCheckingLocalAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Jika sudah login secara lokal, langsung ke home
    if (_isLocallyLoggedIn) {
      // AuthProvider akan memvalidasi sesi di belakang layar
      return Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Tampilkan loading jika AuthProvider masih inisialisasi
          if (!authProvider.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Jika sudah login tapi profil belum lengkap
          if (authProvider.isLoggedIn && !_isProfileComplete(context)) {
            return const ProfileOnboardingScreen();
          }
          
          // Jika sudah login dan profil lengkap
          if (authProvider.isLoggedIn) {
            return const HomeScreen();
          }
          
          // Jika ternyata sudah tidak login (validasi di belakang gagal)
          return const LoginScreen();
        },
      );
    }

    // Jika belum login secara lokal, gunakan AuthProvider normal
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Jika loading, tampilkan indikator loading
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Pengguna belum login
        if (!authProvider.isLoggedIn) {
          print('DEBUG: User not logged in');
          return const LoginScreen();
        }
        
        // Pengguna sudah login tapi profil belum lengkap
        if (!_isProfileComplete(context)) {
          print('DEBUG: Navigating to profile onboarding');
          return const ProfileOnboardingScreen();
        }
        
        // Pengguna sudah login dan profil sudah lengkap
        print('DEBUG: Navigating to home screen');
        return const HomeScreen();
      },
    );
  }
}