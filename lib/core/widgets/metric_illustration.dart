import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Renders one of the extracted line-art illustrations (heart / steps / spo2 /
/// calories), swapping to the dark-line variant on light theme for contrast.
class MetricIllustration extends StatelessWidget {
  const MetricIllustration({required this.name, this.height = 104, super.key});

  /// One of: `heart`, `steps`, `spo2`, `calories`.
  final String name;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTokens.of(context).isDark;
    final asset = isDark
        ? 'assets/illustrations/$name.png'
        : 'assets/illustrations/${name}_light.png';
    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => SizedBox(width: height, height: height),
    );
  }
}
