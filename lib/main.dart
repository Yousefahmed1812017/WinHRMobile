import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/notification_service.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Hive (local cache) ──────────────────────────────────────────────
  await Hive.initFlutter();

  // ── Firebase & FCM Notifications ─────────────────────────────────────
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('[main.dart] Error initializing NotificationService: $e');
  }

  // ── Run App ─────────────────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: WinHRApp(),
    ),
  );
}
