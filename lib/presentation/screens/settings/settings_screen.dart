import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_accent.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/health_models.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../../blocs/theme/theme_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late HealthSettingsModel _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = context.read<DashboardBloc>().state.summary?.settings ??
        HealthSettingsModel.defaults;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final isDark = context.read<ThemeCubit>().state.isDark;
    try {
      await context.read<DashboardBloc>().saveSettings(
        _draft.copyWith(darkMode: isDark),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Thresholds saved.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save settings. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        Text(
          'Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        _ProfileCard(),
        const SizedBox(height: 16),
        _AppearanceCard(),
        const SizedBox(height: 16),
        _ThresholdsCard(
          draft: _draft,
          onChanged: (next) => setState(() => _draft = next),
          saving: _saving,
          onSave: _save,
        ),
        const SizedBox(height: 16),
        _ApiTokenCard(),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.profile?.email ?? '',
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
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
              Row(
                children: [
                  for (final accent in AppAccent.values) ...[
                    _Swatch(
                      accent: accent,
                      selected: accent == themeState.accent,
                      onTap: () => cubit.setAccent(accent),
                    ),
                    const SizedBox(width: 14),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.accent, required this.selected, required this.onTap});

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
                ? const Icon(Icons.check_rounded, size: 20, color: Color(0xFF15161C))
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

class _ThresholdsCard extends StatelessWidget {
  const _ThresholdsCard({
    required this.draft,
    required this.onChanged,
    required this.saving,
    required this.onSave,
  });

  final HealthSettingsModel draft;
  final ValueChanged<HealthSettingsModel> onChanged;
  final bool saving;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Personal Thresholds'),
          const SizedBox(height: 10),
          _Slider(
            label: 'Min SpO₂',
            valueLabel: '${draft.spo2Min.round()}%',
            value: draft.spo2Min,
            min: 80,
            max: 100,
            divisions: 20,
            onChanged: (v) => onChanged(draft.copyWith(spo2Min: v.roundToDouble())),
          ),
          _Slider(
            label: 'Max heart rate',
            valueLabel: '${draft.heartRateMax} bpm',
            value: draft.heartRateMax.toDouble(),
            min: 80,
            max: 220,
            divisions: 140,
            onChanged: (v) => onChanged(draft.copyWith(heartRateMax: v.round())),
          ),
          _Slider(
            label: 'Daily steps',
            valueLabel: '${draft.dailyStepsGoal}',
            value: draft.dailyStepsGoal.toDouble(),
            min: 1000,
            max: 50000,
            divisions: 49,
            onChanged: (v) => onChanged(draft.copyWith(dailyStepsGoal: v.round())),
          ),
          _Slider(
            label: 'Sleep target',
            valueLabel: '${draft.sleepTargetHours.toStringAsFixed(1)} h',
            value: draft.sleepTargetHours,
            min: 4,
            max: 12,
            divisions: 16,
            onChanged: (v) => onChanged(draft.copyWith(sleepTargetHours: v)),
          ),
          const SizedBox(height: 6),
          _SwitchRow(
            label: 'Local health notifications',
            value: draft.notificationsEnabled,
            onChanged: (v) => onChanged(draft.copyWith(notificationsEnabled: v)),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF15161C),
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(saving ? 'Saving…' : 'Save thresholds'),
          ),
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(
              valueLabel,
              style: AppTypography.monoStyle(
                13,
                FontWeight.w700,
                color: AppTokens.of(context).accentColor,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
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

class _ApiTokenCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Developer API Token'),
          const SizedBox(height: 4),
          Text(
            'Use this Firebase ID token to test API endpoints via Swagger.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showToken(context),
            icon: const Icon(Icons.vpn_key_rounded),
            label: const Text('View & copy token'),
          ),
        ],
      ),
    );
  }

  Future<void> _showToken(BuildContext context) async {
    final theme = Theme.of(context);
    final token = await context.read<AuthBloc>().idToken();
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your API Token'),
        content: SingleChildScrollView(
          child: SelectableText(
            token ?? 'Unable to retrieve token.',
            style: AppTypography.monoStyle(
              11,
              FontWeight.w400,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          if (token != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token copied to clipboard')),
                );
              },
              icon: const Icon(Icons.content_copy_rounded, size: 18),
              label: const Text('Copy'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
