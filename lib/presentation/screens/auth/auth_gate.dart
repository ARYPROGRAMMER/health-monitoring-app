import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/cache_keys.dart';
import '../../../data/services/cache_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../home/main_shell.dart';
import '../onboarding/onboarding_screen.dart';
import '../splash/splash_screen.dart';
import 'auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (p, n) => p.status != n.status,
      builder: (context, state) {
        final child = switch (state.status) {
          AuthStatus.unknown => const SplashScreen(),
          AuthStatus.authenticated => const MainShell(),
          AuthStatus.unauthenticated => const _UnauthenticatedFlow(),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: KeyedSubtree(key: ValueKey(state.status), child: child),
        );
      },
    );
  }
}

class _UnauthenticatedFlow extends StatefulWidget {
  const _UnauthenticatedFlow();

  @override
  State<_UnauthenticatedFlow> createState() => _UnauthenticatedFlowState();
}

class _UnauthenticatedFlowState extends State<_UnauthenticatedFlow> {
  late bool _onboarded;

  @override
  void initState() {
    super.initState();
    _onboarded =
        context.read<CacheService>().readString(CacheKeys.onboarded) == 'true';
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded) return const AuthScreen();
    return OnboardingScreen(
      onDone: () {
        context.read<CacheService>().writeString(CacheKeys.onboarded, 'true');
        setState(() => _onboarded = true);
      },
    );
  }
}
