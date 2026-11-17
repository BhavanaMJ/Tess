import 'package:flutter/material.dart';
import '../core/auth/auth_service.dart';
import '../core/auth/auth_state.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/futures/screens/futures_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';
import '../features/profile/screens/profile_screen.dart';

/// The Root Widget of the TESS Flutter application.
/// It configures MaterialApp, the spatial dark theme, and mounts the AuthGate.
class TessApp extends StatelessWidget {
  final AuthService? authService;

  const TessApp({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: AuthGate(authService: authService),
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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
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
            icon: Icon(Icons.fingerprint_outlined),
            activeIcon: Icon(Icons.fingerprint),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
