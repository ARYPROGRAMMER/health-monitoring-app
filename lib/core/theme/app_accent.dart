import 'package:flutter/material.dart';

/// Selectable accent identities matching the Fitbit-style design variants.
enum AppAccent { pink, gold, green }

extension AppAccentX on AppAccent {
  String get label => switch (this) {
    AppAccent.pink => 'Rose',
    AppAccent.gold => 'Gold',
    AppAccent.green => 'Mint',
  };

  /// The vivid driver color used for highlights, glows and selected states.
  Color get primary => switch (this) {
    AppAccent.pink => const Color(0xFFF2789F),
    AppAccent.gold => const Color(0xFFD9AE45),
    AppAccent.green => const Color(0xFF34D17A),
  };

  /// A brighter neon tone used for ECG strips, ring fills and glow shadows.
  Color get glow => switch (this) {
    AppAccent.pink => const Color(0xFFFF6FA3),
    AppAccent.gold => const Color(0xFFE9C66B),
    AppAccent.green => const Color(0xFF4ADE80),
  };

  /// Soft gradient used for the activity-card blobs and stacked surfaces.
  List<Color> get blob => switch (this) {
    AppAccent.pink => const [Color(0xFFE9A6BC), Color(0xFF7C4A59)],
    AppAccent.gold => const [Color(0xFFD8BC6A), Color(0xFF6E5C2E)],
    AppAccent.green => const [Color(0xFF8FD9A8), Color(0xFF34684C)],
  };

  /// The light-theme background wash.
  Color get lightWash => switch (this) {
    AppAccent.pink => const Color(0xFFFBE9EF),
    AppAccent.gold => const Color(0xFFF6EFDC),
    AppAccent.green => const Color(0xFFE6F6EC),
  };

  static AppAccent fromName(String? name) {
    return AppAccent.values.firstWhere(
      (accent) => accent.name == name,
      orElse: () => AppAccent.pink,
    );
  }
}
