import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../data/repositories/health_repository.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/add_reading_sheet.dart';
import '../alerts/alerts_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (context) =>
          DashboardBloc(repository: context.read<HealthRepository>())
            ..add(const DashboardStarted()),
      child: const _MainShellView(),
    );
  }
}

class _MainShellView extends StatefulWidget {
  const _MainShellView();

  @override
  State<_MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<_MainShellView> {
  int _index = 0;

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onShowAlerts: () => _go(1)),
      const AlertsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: _index, children: pages),
        ),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () => AddReadingSheet.show(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: BlocBuilder<DashboardBloc, DashboardState>(
        buildWhen: (p, n) =>
            (p.summary?.activeAlerts.length ?? 0) !=
            (n.summary?.activeAlerts.length ?? 0),
        builder: (context, state) => AppBottomNav(
          currentIndex: _index,
          onTap: _go,
          items: [
            const AppBottomNavItem(
              icon: Icons.dashboard_rounded,
              label: 'Home',
            ),
            AppBottomNavItem(
              icon: Icons.warning_amber_rounded,
              label: 'Alerts',
              badge: state.summary?.activeAlerts.length ?? 0,
            ),
            const AppBottomNavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
