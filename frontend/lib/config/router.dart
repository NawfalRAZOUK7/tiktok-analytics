import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/post.dart';
import '../screens/analytics_dashboard_screen.dart';
import '../screens/followers_analysis_screen.dart';
import '../screens/followers_screen.dart';
import '../screens/following_screen.dart';
import '../screens/login_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/post_list_screen.dart';
import '../screens/register_screen.dart';

/// Router configuration for the app
class AppRouter {
  /// Create router with authentication redirect logic
  static GoRouter createRouter({
    required bool Function() isAuthenticated,
    required VoidCallback onAuthChange,
  }) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final authenticated = isAuthenticated();
        final loggingIn =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        // Redirect to login if not authenticated and not already on login/register
        if (!authenticated && !loggingIn) {
          return '/login';
        }

        // Redirect to home if authenticated and on login/register
        if (authenticated && loggingIn) {
          return '/';
        }

        // No redirect needed
        return null;
      },
      refreshListenable: AuthChangeNotifier(onAuthChange),
      routes: [
        // Auth routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Main shell route with bottom navigation
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(child: child);
          },
          routes: [
            // Dashboard
            GoRoute(
              path: '/',
              name: 'dashboard',
              builder: (context, state) => const AnalyticsDashboardScreen(),
            ),

            // Posts list
            GoRoute(
              path: '/posts',
              name: 'posts',
              builder: (context, state) => const PostListScreen(),
              routes: [
                // Post detail
                GoRoute(
                  path: ':id',
                  name: 'post-detail',
                  builder: (context, state) {
                    final post = state.extra as Post?;
                    if (post != null) {
                      return PostDetailScreen(post: post);
                    }
                    // If no post is passed, show error or redirect
                    return Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: const Center(
                        child: Text(
                          'Post not found. Please go back and try again.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Analytics
            GoRoute(
              path: '/analytics',
              name: 'analytics',
              builder: (context, state) => const AnalyticsDashboardScreen(),
            ),

            // Followers
            GoRoute(
              path: '/followers',
              name: 'followers',
              builder: (context, state) => const FollowersScreen(),
            ),

            // Following
            GoRoute(
              path: '/following',
              name: 'following',
              builder: (context, state) => const FollowingScreen(),
            ),

            // Followers Analysis
            GoRoute(
              path: '/followers-analysis',
              name: 'followers-analysis',
              builder: (context, state) => const FollowersAnalysisScreen(),
            ),
          ],
        ),
      ],
      errorBuilder:
          (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Page not found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.uri.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

/// Notifier for auth state changes
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(VoidCallback onAuthChange) {
    _onAuthChange = onAuthChange;
  }

  late VoidCallback _onAuthChange;

  void notify() {
    _onAuthChange();
    notifyListeners();
  }
}

/// Main shell with bottom navigation
class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _onItemTapped(BuildContext context, int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/posts');
        break;
      case 2:
        context.go('/analytics');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update selected index based on current location
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/posts')) {
      _selectedIndex = 1;
    } else if (location.startsWith('/analytics')) {
      _selectedIndex = 2;
    } else {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TikTok Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh current screen
              // This will be handled by the screen itself
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Logout will be handled by AuthProvider
              // context.read<AuthProvider>().logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
