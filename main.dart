import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cardio_workout_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/db_debug_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/background_effects.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart';
import 'services/custom_workout_service.dart';
import 'services/step_counter_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite_ffi for Windows platform
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => StepCounterService()),
        ChangeNotifierProxyProvider<AuthService, ReminderService>(
          create: (context) => ReminderService(Provider.of<AuthService>(context, listen: false)),
          update: (context, authService, previous) => 
            previous ?? ReminderService(authService),
        ),
        ChangeNotifierProxyProvider<AuthService, CustomWorkoutService>(
          create: (context) => CustomWorkoutService(Provider.of<AuthService>(context, listen: false)),
          update: (context, authService, previous) => 
            previous ?? CustomWorkoutService(authService),
        ),
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
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark theme for futuristic look
      home: const AuthWrapper(),
    );
  }
}

// Wrapper to check authentication state and route accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Show loading indicator while initializing
    if (!authService.isInitialized) {
      debugPrint('AuthWrapper: Auth service not initialized yet');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }
    
    // Navigate based on authentication state
    if (authService.isAuthenticated) {
      debugPrint('AuthWrapper: User is authenticated, showing MainScreen');
      return const MainScreen();
    } else {
      debugPrint('AuthWrapper: User is not authenticated, showing LoginScreen');
      return const LoginScreen();
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  // Start with the profile tab (index 4) selected by default
  int _selectedIndex = 4;
  late AnimationController _animationController;
  final List<String> _titles = [
    'Fitness Tracker', 
    'Cardio Workouts', 
    'Reminders', 
    'Alerts', 
    'Profile',
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const CardioWorkoutScreen(),
    const RemindersScreen(),
    const NotificationScreen(),
    const UserProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
    
    // Initialize notification service
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    notificationService.initialize();
    
    // Add debug log to confirm profile tab is selected
    debugPrint('MainScreen initialized with Profile tab (index $_selectedIndex)');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _animationController.reset();
      _animationController.forward();
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Background effects
          const Positioned.fill(
            child: BackgroundEffects(),
          ),
          
          // Main content with fade transition
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
            ),
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            backgroundColor: Colors.black.withOpacity(0.5),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_run),
                label: 'Cardio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.alarm),
                label: 'Reminders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Alerts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDrawer() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.2),
              Colors.black,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
              accountName: Text(
                user?.name ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.name?.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 24,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to help screen
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Database Debug'),
              subtitle: const Text('For troubleshooting only'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DbDebugScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await authService.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
} 