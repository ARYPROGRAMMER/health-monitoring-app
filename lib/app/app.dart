import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/profile/profile_cubit.dart';
import '../presentation/blocs/theme/theme_cubit.dart';
import '../presentation/screens/auth/auth_gate.dart';

class StealtheraApp extends StatelessWidget {
  const StealtheraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Stealthera',
          theme: AppTheme.build(
            accent: themeState.accent,
            brightness: Brightness.light,
          ),
          darkTheme: AppTheme.build(
            accent: themeState.accent,
            brightness: Brightness.dark,
          ),
          themeMode: themeState.mode,
          home: const _AppRoot(),
        );
      },
    );
  }
}

/// Bridges the auth session to the profile stream without coupling blocs.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (p, n) => p.status != n.status || p.user?.uid != n.user?.uid,
      listener: (context, state) {
        final profile = context.read<ProfileCubit>();
        if (state.status == AuthStatus.authenticated && state.user != null) {
          profile.watch(state.user!.uid);
        } else if (state.status == AuthStatus.unauthenticated) {
          profile.clear();
        }
      },
      child: const AuthGate(),
    );
  }
}
