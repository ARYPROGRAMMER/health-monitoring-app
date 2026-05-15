import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/app_providers.dart';
import '../home/home_screen.dart';
import 'auth_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: user == null ? const AuthScreen() : const HomeScreen(),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
