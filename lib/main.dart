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
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/profile_onboarding_screen.dart';
import 'screens/scan/scan_screen.dart';
import 'utils/app_colors.dart';
import 'services/firestore_service.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FoodScanProvider>(
          create: (_) => FoodScanProvider(dotenv.env['GEMINI_API_KEY'] ?? ''),
          update: (context, auth, scanProvider) {
            scanProvider!.setUserId(auth.currentUserId);
            return scanProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodWise',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF070707),
          secondary: Color(0xFFD9DDE0),
          surface: Color(0xFFFFFFFF),
          error: AppColors.errorColor,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF070707),
          foregroundColor: AppColors.textLight,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF070707),
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
        foregroundColor: const Color(0xFF070707),
        side: const BorderSide(color: Color(0xFF070707)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF070707),
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFFFFFFFF),
          elevation: 2,
          shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF070707),
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
          backgroundColor: Color(0xFFFFFFFF),
          selectedItemColor: Color(0xFF070707),
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
      home: FutureBuilder(
        future: _initializeApp(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Show loading indicator
          }
          return const AuthWrapper();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/profile': (context) => const ProfileOnboardingScreen(),
        '/scan': (context) => const ScanScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }

  Future<void> _initializeApp(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final completer = Completer<void>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await authProvider.loadUser();
        if (authProvider.user != null) {
          await firestoreService.initializeUserQuests(authProvider.user!.id);
        }
        completer.complete();
      } catch (e) {
        print('Error initializing app: $e');
        completer.completeError(e);
      }
    });
    
    return completer.future;
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
            return const AnimatedLoadingScreen();
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
          return const WelcomeScreen();
        },
      );
    }

    // Jika belum login secara lokal, tampilkan welcome screen
    return const WelcomeScreen();
  }
}

class AnimatedLoadingScreen extends StatefulWidget {
  const AnimatedLoadingScreen({super.key});

  @override
  State<AnimatedLoadingScreen> createState() => _AnimatedLoadingScreenState();
}

class _AnimatedLoadingScreenState extends State<AnimatedLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -20 * (1 - _logoAnimation.value)),
                  child: Opacity(
                    opacity: _logoAnimation.value,
                    child: Image.asset(
                      'assets/images/logo-ahshaka.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _loadingAnimation.value,
                  child: const CircularProgressIndicator(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}