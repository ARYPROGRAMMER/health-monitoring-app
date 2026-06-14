import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/health_repository.dart';
import 'data/services/cache_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/stealthera_api.dart';
import 'firebase_options.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/profile/profile_cubit.dart';
import 'presentation/blocs/theme/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();
  await _loadEnv();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
    await Hive.initFlutter();
    final cacheBox = await Hive.openBox<dynamic>('stealthera_cache');
    runApp(StealtheraRoot(cacheBox: cacheBox));
    unawaited(_initBackgroundServices());
  } catch (error, stack) {
    developer.log('Startup failed', error: error, stackTrace: stack, name: 'Stealthera');
    runApp(StartupFailureApp(error: error));
  }
}

/// Routes framework + async errors to structured logs instead of crashing.
void _installErrorHandlers() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    developer.log(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
      name: 'Stealthera',
    );
    previous?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('Uncaught', error: error, stackTrace: stack, name: 'Stealthera');
    return true;
  };
}

/// Loads `.env` if present; otherwise initialises dotenv empty so config reads
/// fall back to dart-defines / defaults without throwing.
Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    try {
      dotenv.testLoad(fileInput: '');
    } catch (_) {}
  }
}

Future<void> _initBackgroundServices() async {
  try {
    await NotificationService.instance.initialize().timeout(
      const Duration(seconds: 8),
    );
  } catch (_) {}
}

/// Wires the data layer and session-level blocs above the [StealtheraApp].
/// Dependencies are built once in [initState] so rebuilds never recreate them.
class StealtheraRoot extends StatefulWidget {
  const StealtheraRoot({required this.cacheBox, super.key});

  final Box<dynamic> cacheBox;

  @override
  State<StealtheraRoot> createState() => _StealtheraRootState();
}

class _StealtheraRootState extends State<StealtheraRoot> {
  late final CacheService _cacheService;
  late final AuthRepository _authRepository;
  late final HealthRepository _healthRepository;

  @override
  void initState() {
    super.initState();
    final firebaseAuth = FirebaseAuth.instance;
    _cacheService = CacheService(widget.cacheBox);
    _authRepository = AuthRepository(
      firebaseAuth: firebaseAuth,
      firestore: FirebaseFirestore.instance,
      googleSignIn: GoogleSignIn.instance,
    );
    _healthRepository = HealthRepository(
      api: StealtheraApi(),
      cache: _cacheService,
    );
    if (AppConfig.verboseLogging) {
      developer.log('API base: ${AppConfig.apiBaseUrl}', name: 'Stealthera');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _cacheService),
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _healthRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc(_authRepository)),
          BlocProvider(create: (_) => ThemeCubit(_cacheService)),
          BlocProvider(create: (_) => ProfileCubit(_authRepository)),
        ],
        child: const StealtheraApp(),
      ),
    );
  }
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5A6E), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Stealthera could not start',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
