import 'package:flutter/material.dart';

import '../presentation/screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

class StealtheraApp extends StatelessWidget {
  const StealtheraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stealthera',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}
