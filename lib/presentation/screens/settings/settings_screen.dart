import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_accent.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/device_models.dart';
import '../../../data/repositories/health_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/common/load_cubit.dart';
import '../../blocs/devices/devices_bloc.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../../blocs/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LoadCubit<ApiHealth>(() => context.read<HealthRepository>().apiHealth())
            ..load(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        Text(
          'Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        const _ProfileCard(),
        const SizedBox(height: 16),
        const _AppearanceCard(),
        const SizedBox(height: 16),
        const _BackendCard(),
        const SizedBox(height: 16),
        const _ActiveDeviceCard(),
        const SizedBox(height: 16),
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Account'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) => GlowCard(
        child: Row(
          children: [
            ProfileAvatar(photoUrl: state.profile?.photoUrl, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.profile?.email ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final cubit = context.read<ThemeCubit>();
        return GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Appearance'),
              const SizedBox(height: 8),
              _SwitchRow(
                label: 'Dark mode',
                value: themeState.isDark,
                onChanged: cubit.setDark,
              ),
              const SizedBox(height: 14),
              Text(
                'Accent',
                style: AppTypography.monoStyle(
                  12,
                  FontWeight.w400,
                  color: AppTokens.of(context).textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (final accent in AppAccent.values)
                    _Swatch(
                      accent: accent,
                      selected: accent == themeState.accent,
                      onTap: () => cubit.setAccent(accent),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BackendCard extends StatelessWidget {
  const _BackendCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadCubit<ApiHealth>, Async<ApiHealth>>(
      builder: (context, state) {
        final health = state.data;
        final tokens = AppTokens.of(context);
        final ok = health?.ok == true;
        return GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: SectionHeader('Backend')),
                  IconButton(
                    tooltip: 'Refresh backend status',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.read<LoadCubit<ApiHealth>>().load();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoLine(label: 'API', value: AppConfig.apiBaseUrl),
              _InfoLine(label: 'Timezone', value: AppConfig.timezone),
              _InfoLine(
                label: 'Health',
                value: state.isLoading
                    ? 'Checking...'
                    : state.error ?? (ok ? 'OK' : health?.status ?? 'Unknown'),
                color: ok ? tokens.success : tokens.warning,
              ),
              _InfoLine(
                label: 'Mongo',
                value: health?.mongo ?? '--',
                color: health?.mongo == 'up' ? tokens.success : null,
              ),
              _InfoLine(
                label: 'Realtime',
                value: health?.realtime ?? '--',
                color: health?.realtimeConnected == true
                    ? tokens.success
                    : tokens.warning,
              ),
              _InfoLine(
                label: 'SSE clients',
                value: health?.sseClients.toString() ?? '--',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveDeviceCard extends StatelessWidget {
  const _ActiveDeviceCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesBloc, DevicesState>(
      buildWhen: (p, n) =>
          p.activeDeviceId != n.activeDeviceId || p.devices != n.devices,
      builder: (context, state) {
        final device = state.activeDevice;
        return GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Active Device'),
              const SizedBox(height: 12),
              _InfoLine(label: 'Device', value: device?.displayName ?? '--'),
              _InfoLine(label: 'IMEI', value: state.activeDeviceId ?? '--'),
              _InfoLine(label: 'Status', value: device?.status ?? '--'),
            ],
          ),
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textMuted,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '--' : value,
              style: AppTypography.monoStyle(
                12,
                FontWeight.w700,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.glow.withValues(alpha: 0.5),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: Color(0xFF15161C),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            accent.label,
            style: AppTypography.monoStyle(
              11,
              FontWeight.w400,
              color: AppTokens.of(context).textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
