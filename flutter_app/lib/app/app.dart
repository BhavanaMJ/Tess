import 'package:flutter/material.dart';
import '../core/auth/auth_service.dart';
import '../core/auth/auth_state.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/futures/screens/futures_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';
import '../features/profile/screens/profile_screen.dart';

/// The Root Widget of the TESS Flutter application.
/// It configures MaterialApp with Light Theme as default, Dark Theme, and persistent ThemeMode.
class TessApp extends StatelessWidget {
  final AuthService? authService;

  const TessApp({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: AuthGate(authService: authService),
        );
      },
    );
  }
}

/// AuthGate monitors Supabase authentication state and automatically switches
/// between the Unauthenticated (LoginScreen) and Authenticated (MainNavigationShell) views.
class AuthGate extends StatelessWidget {
  final AuthService? authService;

  const AuthGate({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    final service = authService ?? AuthService();

    return StreamBuilder<TessAuthState>(
      stream: service.authStateChanges,
      builder: (context, snapshot) {
        // 1. If active event from stream is authenticated
        if (snapshot.hasData && snapshot.data!.isAuthenticated) {
          return const MainNavigationShell();
        }

        // 2. Initial state before first stream emission: check synchronous session
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (service.isAuthenticated) {
            return const MainNavigationShell();
          }
          return LoginScreen(authService: service);
        }

        // 3. Explicit unauthenticated or signed out state
        return LoginScreen(authService: service);
      },
    );
  }
}

/// MainNavigationShell hosts the persistent bottom navigation bar
/// and switches between the primary feature screens.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigateTab: _onTabTapped),
      const ChatScreen(),
      const FuturesScreen(),
      const TasksScreen(),
      const ProfileScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF22302D) : const Color(0xFFE2EAE7),
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Futures',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_outlined),
              activeIcon: Icon(Icons.task_alt),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
