import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/environment.dart';
import 'config/router.dart';
import 'providers/analytics_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

void main() {
  // Print environment configuration in development
  if (Environment.isDevelopment) {
    Environment.printConfig();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final authService = AuthService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (context) => PostProvider()),
        ChangeNotifierProvider(
          create: (context) => AnalyticsProvider(apiService),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final router = AppRouter.createRouter(
            isAuthenticated: () => authProvider.isAuthenticated,
            onAuthChange: () {
              // Trigger rebuild when auth state changes
            },
          );

          return MaterialApp.router(
            title: 'TikTok Analytics',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
