import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/health_models.dart';
import '../controllers/dashboard_controller.dart';
import 'glass_panel.dart';

class AddReadingSheet extends ConsumerStatefulWidget {
  const AddReadingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddReadingSheet(),
    );
  }

  @override
  ConsumerState<AddReadingSheet> createState() => _AddReadingSheetState();
}

class _AddReadingSheetState extends ConsumerState<AddReadingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  _ReadingOption _selected = _readingOptions.first;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        borderRadius: 30,
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.18,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add Health Reading',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Close',
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Record a current measurement and Stealthera will update your timeline.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _readingOptions.map((option) {
                    final selected = option == _selected;

                    return ChoiceChip(
                      showCheckmark: false,
                      selected: selected,
                      onSelected: _isSubmitting
                          ? null
                          : (_) => setState(() {
                              _selected = option;
                              _valueController.clear();
                              _errorMessage = null;
                            }),
                      selectedColor: option.color.withValues(alpha: 0.18),
                      backgroundColor: theme.colorScheme.surface.withValues(
                        alpha: 0.62,
                      ),
                      avatar: Icon(
                        option.icon,
                        size: 18,
                        color: selected
                            ? option.color
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        option.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: selected ? option.color : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _valueController,
                  enabled: !_isSubmitting,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: _selected.inputLabel,
                    suffixText: _selected.unit,
                    prefixIcon: Icon(_selected.icon, color: _selected.color),
                  ),
                  validator: _validateValue,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selected.quickValues.map((value) {
                    final label = _formatQuickValue(value);

                    return ActionChip(
                      avatar: Icon(_selected.icon, size: 16),
                      label: Text(label),
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              _valueController.text = value.toString();
                              _formKey.currentState?.validate();
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _ReadingContext(option: _selected),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.cloud_sync_rounded),
                  label: Text(
                    _isSubmitting ? 'Syncing reading' : 'Sync Reading',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateValue(String? rawValue) {
    final value = double.tryParse(rawValue?.trim() ?? '');

    if (value == null) {
      return 'Enter a numeric value';
    }

    if (value < _selected.min || value > _selected.max) {
      return '${_selected.label} must be ${_formatRange(_selected.min)}-${_formatRange(_selected.max)} ${_selected.unit}';
    }

    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final value = double.parse(_valueController.text.trim());
    final reading = HealthReadingModel(
      type: _selected.type,
      value: value,
      unit: _selected.unit,
      recordedAt: DateTime.now(),
    );

    try {
      await ref.read(dashboardControllerProvider.notifier).syncReading(reading);

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_selected.label} synced to your health timeline.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _errorMessage = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('401') || message.contains('403')) {
      return 'Your session needs a fresh sign-in before syncing readings.';
    }

    if (message.contains('SocketException') || message.contains('timeout')) {
      return 'The sync service is not reachable. Try again when the service is online.';
    }

    return 'Reading could not be synced. Please try again.';
  }

  String _formatQuickValue(double value) {
    final formatted = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return '$formatted ${_selected.unit}';
  }

  static String _formatRange(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }
}

class _ReadingContext extends StatelessWidget {
  const _ReadingContext({required this.option});

  final _ReadingOption option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: option.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: option.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(option.icon, color: option.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              option.context,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingOption {
  const _ReadingOption({
    required this.type,
    required this.label,
    required this.inputLabel,
    required this.unit,
    required this.icon,
    required this.color,
    required this.min,
    required this.max,
    required this.quickValues,
    required this.context,
  });

  final String type;
  final String label;
  final String inputLabel;
  final String unit;
  final IconData icon;
  final Color color;
  final double min;
  final double max;
  final List<double> quickValues;
  final String context;
}

const _readingOptions = [
  _ReadingOption(
    type: 'heart_rate',
    label: 'Heart Rate',
    inputLabel: 'Heart rate',
    unit: 'bpm',
    icon: Icons.favorite_rounded,
    color: Color(0xFFFB7185),
    min: 30,
    max: 220,
    quickValues: [62, 78, 96, 124],
    context: 'Compared with your personalized heart rate range for alerting.',
  ),
  _ReadingOption(
    type: 'spo2',
    label: 'SpO2',
    inputLabel: 'Oxygen saturation',
    unit: '%',
    icon: Icons.air_rounded,
    color: Color(0xFF2DD4BF),
    min: 70,
    max: 100,
    quickValues: [92, 95, 97, 99],
    context: 'Checked against your minimum SpO2 threshold and alert history.',
  ),
  _ReadingOption(
    type: 'sleep',
    label: 'Sleep',
    inputLabel: 'Sleep duration',
    unit: 'hours',
    icon: Icons.nightlight_round,
    color: Color(0xFF60A5FA),
    min: 0,
    max: 24,
    quickValues: [5.5, 7, 7.5, 8],
    context: 'Used for sleep trend charts and target comparison insights.',
  ),
  _ReadingOption(
    type: 'activity',
    label: 'Activity',
    inputLabel: 'Step count',
    unit: 'steps',
    icon: Icons.directions_walk_rounded,
    color: Color(0xFFF59E0B),
    min: 0,
    max: 100000,
    quickValues: [2500, 6000, 8000, 12000],
    context: 'Rolled into activity charts and daily goal progress.',
  ),
];
