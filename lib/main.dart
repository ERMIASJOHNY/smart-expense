import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/send_money_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/transaction.dart';
import 'models/contact.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start orientation lock, but don't strictly await it if it delays startup
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 1. Initialize Hive and Boxes
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(PaymentCategoryAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(ContactAdapter());

  await Future.wait([
    Hive.openBox<Transaction>('transactions_cache'),
    Hive.openBox<Contact>('contacts_cache'),
  ]);

  // 2. Initialize Firebase
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBO1w4nPI9vI5yB3zSA82GG3RRf4F97jt4",
          authDomain: "smart-expense-ad392.firebaseapp.com",
          projectId: "smart-expense-ad392",
          storageBucket: "smart-expense-ad392.firebasestorage.app",
          messagingSenderId: "965814387806",
          appId: "1:965814387806:web:b7be097a375f578fe720cf",
        ),
      );
    } else {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    }
  } catch (e) {
    debugPrint('Firebase initialization failed or timed out: $e');
    debugPrint('The app will continue in offline mode (Hive cache only).');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
        ));

        return MaterialApp(
          title: 'Smart Expense Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/': (context) => const MainShell(),
            '/add-transaction': (context) => const AddTransactionScreen(),
            '/history': (context) => const HistoryScreen(),
            '/statistics': (context) => const StatisticsScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/about_us': (context) => const AboutUsScreen(),
            '/send': (context) => const SendMoneyScreen(),
            '/admin': (context) => const AdminPanelScreen(),
          },
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

    final List<Widget> screens = [
      const HomeScreen(),
      const StatisticsScreen(),
      if (isAdmin) const AdminPanelScreen(showAppBar: false),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart),
        label: 'Stats',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Users',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history_outlined),
        activeIcon: Icon(Icons.history),
        label: 'History',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex:
                  _selectedIndex >= navItems.length ? 0 : _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: isDark ? Colors.white54 : Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: navItems,
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/add-transaction'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
