import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'data/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
    await Hive.initFlutter();
    await Hive.openBox<dynamic>('stealthera_cache');
    runApp(const ProviderScope(child: StealtheraApp()));
    unawaited(_initializeBackgroundServices());
  } catch (error) {
    runApp(StartupFailureApp(error: error));
  }
}

Future<void> _initializeBackgroundServices() async {
  await _guardedStartupTask(NotificationService.instance.initialize());
}

Future<void> _guardedStartupTask(Future<void> task) async {
  try {
    await task.timeout(const Duration(seconds: 8));
  } catch (_) {}
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Stealthera could not start.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
