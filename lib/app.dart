import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:win_hr/core/localization/generated/app_localizations.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/data/auth_provider.dart';

/// Root widget for Win HR.
class WinHRApp extends ConsumerStatefulWidget {
  const WinHRApp({super.key});

  @override
  ConsumerState<WinHRApp> createState() => _WinHRAppState();
}

class _WinHRAppState extends ConsumerState<WinHRApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth state globally on app start
    Future.microtask(() {
      ref.read(authStateProvider.notifier).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lock Sys HR',
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // ── Localization ───────────────────────────────────────────────
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Routing ────────────────────────────────────────────────────
      routerConfig: AppRouter.router,
    );
  }
}
