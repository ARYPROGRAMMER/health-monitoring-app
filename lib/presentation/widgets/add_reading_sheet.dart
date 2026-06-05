import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/health_models.dart';
import '../blocs/dashboard/dashboard_bloc.dart';

class _Option {
  const _Option({
    required this.type,
    required this.label,
    required this.unit,
    required this.icon,
    required this.min,
    required this.max,
    required this.quick,
  });

  final String type;
  final String label;
  final String unit;
  final IconData icon;
  final double min;
  final double max;
  final List<double> quick;
}

const _options = [
  _Option(type: 'heart_rate', label: 'Heart Rate', unit: 'bpm', icon: Icons.favorite_rounded, min: 30, max: 220, quick: [62, 78, 96, 124]),
  _Option(type: 'spo2', label: 'SpO₂', unit: '%', icon: Icons.air_rounded, min: 70, max: 100, quick: [92, 95, 97, 99]),
  _Option(type: 'sleep', label: 'Sleep', unit: 'hours', icon: Icons.nightlight_round, min: 0, max: 24, quick: [5.5, 7, 7.5, 8]),
  _Option(type: 'activity', label: 'Activity', unit: 'steps', icon: Icons.directions_walk_rounded, min: 0, max: 100000, quick: [2500, 6000, 8000, 12000]),
];

class AddReadingSheet extends StatefulWidget {
  const AddReadingSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<DashboardBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const AddReadingSheet(),
      ),
    );
  }

  @override
  State<AddReadingSheet> createState() => _AddReadingSheetState();
}

class _AddReadingSheetState extends State<AddReadingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  _Option _selected = _options.first;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? raw) {
    final value = double.tryParse(raw?.trim() ?? '');
    if (value == null) return 'Enter a numeric value';
    if (value < _selected.min || value > _selected.max) {
      return '${_selected.label} must be ${_selected.min.round()}-${_selected.max.round()} ${_selected.unit}';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final reading = HealthReadingModel(
      type: _selected.type,
      value: double.parse(_controller.text.trim()),
      unit: _selected.unit,
      recordedAt: DateTime.now(),
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<DashboardBloc>().syncReading(reading);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${_selected.label} synced to your timeline.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendly(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendly(Object error) {
    final message = error.toString();
    if (message.contains('401') || message.contains('403')) {
      return 'Your session needs a fresh sign-in before syncing.';
    }
    if (message.contains('SocketException') || message.contains('timeout')) {
      return 'The sync service is not reachable right now.';
    }
    return 'Reading could not be synced. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
      child: GlowCard(
        glow: true,
        radius: 28,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Add Health Reading',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _options.map((option) {
                    final selected = option == _selected;
                    return ChoiceChip(
                      showCheckmark: false,
                      selected: selected,
                      onSelected: _submitting
                          ? null
                          : (_) => setState(() {
                              _selected = option;
                              _controller.clear();
                              _error = null;
                            }),
                      selectedColor: tokens.accentColor.withValues(alpha: 0.2),
                      backgroundColor: tokens.elevatedCard,
                      side: BorderSide(
                        color: selected ? tokens.accentColor : tokens.cardBorder,
                      ),
                      avatar: Icon(
                        option.icon,
                        size: 18,
                        color: selected ? tokens.accentColor : tokens.textMuted,
                      ),
                      label: Text(option.label),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller,
                  enabled: !_submitting,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: _selected.label,
                    suffixText: _selected.unit,
                    prefixIcon: Icon(_selected.icon),
                  ),
                  validator: _validate,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selected.quick.map((value) {
                    final label = value == value.roundToDouble()
                        ? value.round().toString()
                        : value.toStringAsFixed(1);
                    return ActionChip(
                      label: Text('$label ${_selected.unit}'),
                      backgroundColor: tokens.elevatedCard,
                      side: BorderSide(color: tokens.cardBorder),
                      onPressed: _submitting
                          ? null
                          : () {
                              _controller.text = value.toString();
                              _formKey.currentState?.validate();
                            },
                    );
                  }).toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF15161C),
                          ),
                        )
                      : const Icon(Icons.cloud_sync_rounded),
                  label: Text(_submitting ? 'Syncing…' : 'Sync reading'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
