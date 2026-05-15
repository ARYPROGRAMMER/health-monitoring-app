import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/health_models.dart';
import '../../../data/providers/app_providers.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardControllerProvider);
    final profile = ref.watch(currentUserProfileProvider);

    return dashboard.when(
      data: (summary) {
        final settings = summary?.settings ?? HealthSettingsModel.defaults;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            profile.when(
              data: (userProfile) => _ProfileCard(
                name: userProfile?.displayName ?? 'Stealthera Member',
                email: userProfile?.email ?? '',
                photoUrl: userProfile?.photoUrl,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ProfileCard(
                name: 'Stealthera Member',
                email: error.toString(),
              ),
            ),
            const SizedBox(height: 16),
            _ThresholdsCard(settings: settings),
            const SizedBox(height: 16),
            _ApiTokenCard(),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ref.read(authActionProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EmptyState(
            icon: Icons.settings_suggest_rounded,
            title: 'Unable to load settings',
            message: error.toString(),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.email, this.photoUrl});

  final String name;
  final String email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      child: Row(
        children: [
          photoUrl != null && photoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    photoUrl!,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const BrandMark(size: 58),
                  ),
                )
              : const BrandMark(size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdsCard extends ConsumerStatefulWidget {
  const _ThresholdsCard({required this.settings});

  final HealthSettingsModel settings;

  @override
  ConsumerState<_ThresholdsCard> createState() => _ThresholdsCardState();
}

class _ThresholdsCardState extends ConsumerState<_ThresholdsCard> {
  late HealthSettingsModel _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.settings;
  }

  @override
  void didUpdateWidget(covariant _ThresholdsCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.settings != widget.settings) {
      _draft = widget.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Thresholds',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _SliderRow(
            label: 'Min SpO2',
            valueLabel: '${_draft.spo2Min.round()}%',
            value: _draft.spo2Min,
            min: 80,
            max: 100,
            divisions: 20,
            onChanged: (value) => setState(
              () => _draft = _draft.copyWith(spo2Min: value.roundToDouble()),
            ),
          ),
          _SliderRow(
            label: 'Max heart rate',
            valueLabel: '${_draft.heartRateMax} bpm',
            value: _draft.heartRateMax.toDouble(),
            min: 80,
            max: 220,
            divisions: 140,
            onChanged: (value) => setState(
              () => _draft = _draft.copyWith(heartRateMax: value.round()),
            ),
          ),
          _SliderRow(
            label: 'Daily steps',
            valueLabel: '${_draft.dailyStepsGoal}',
            value: _draft.dailyStepsGoal.toDouble(),
            min: 1000,
            max: 50000,
            divisions: 49,
            onChanged: (value) => setState(
              () => _draft = _draft.copyWith(dailyStepsGoal: value.round()),
            ),
          ),
          _SliderRow(
            label: 'Sleep target',
            valueLabel: '${_draft.sleepTargetHours.toStringAsFixed(1)} h',
            value: _draft.sleepTargetHours,
            min: 4,
            max: 12,
            divisions: 16,
            onChanged: (value) => setState(
              () => _draft = _draft.copyWith(sleepTargetHours: value),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _draft.notificationsEnabled,
            onChanged: (value) => setState(
              () => _draft = _draft.copyWith(notificationsEnabled: value),
            ),
            title: const Text('Local health notifications'),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _draft.darkMode,
            onChanged: (value) {
              setState(() => _draft = _draft.copyWith(darkMode: value));
              ref
                  .read(appThemeModeProvider.notifier)
                  .setDarkMode(value)
                  .ignore();
            },
            title: const Text('Dark mode'),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => ref
                .read(dashboardControllerProvider.notifier)
                .updateSettings(_draft),
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save thresholds'),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
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
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(valueLabel),
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

class _ApiTokenCard extends ConsumerWidget {
  const _ApiTokenCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Developer API Token',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use this token to manually test API endpoints via Swagger',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => _showTokenDialog(context, ref, theme),
            icon: const Icon(Icons.vpn_key_rounded),
            label: const Text('View & Copy Token'),
          ),
        ],
      ),
    );
  }

  void _showTokenDialog(BuildContext context, WidgetRef ref, ThemeData theme) async {
    final authController = ref.read(authActionProvider.notifier);
    final token = await authController.getIdToken();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your API Token'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use this Bearer token in the Authorization header:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SelectableText(
                    token ?? 'Unable to retrieve token',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Token expires in 1 hour and refreshes automatically when you interact with the app.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (token != null)
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Token copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.content_copy_rounded),
                label: const Text('Copy Token'),
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
}
