import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/metric_illustration.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/health_models.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../metrics/metric_detail_screen.dart';
import '../metrics/metric_kind.dart';

class DeviceHubScreen extends StatelessWidget {
  const DeviceHubScreen({super.key});

  static void open(BuildContext context) {
    final bloc = context.read<DashboardBloc>();
    final profile = context.read<ProfileCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: profile),
          ],
          child: const DeviceHubScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Scaffold(
      body: AppBackground(
        glowAlignment: Alignment.center,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Text(
                      'Your Device',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    final summary = state.summary;
                    if (summary == null) return const LoadingView();
                    return LayoutBuilder(
                      builder: (context, constraints) =>
                          _HubLayout(summary: summary, size: constraints.biggest, tokens: tokens),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubLayout extends StatelessWidget {
  const _HubLayout({required this.summary, required this.size, required this.tokens});

  final DashboardSummaryModel summary;
  final Size size;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final cardW = (size.width - 40) / 2 - 8;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _ConnectorPainter(color: tokens.glow)),
        ),
        Center(child: _Device(tokens: tokens)),
        Positioned(
          left: 16,
          top: size.height * 0.04,
          width: cardW,
          child: _HubCard(kind: MetricKind.heart, summary: summary),
        ),
        Positioned(
          right: 16,
          top: size.height * 0.16,
          width: cardW,
          child: _HubCard(kind: MetricKind.spo2, summary: summary),
        ),
        Positioned(
          left: 16,
          bottom: size.height * 0.16,
          width: cardW,
          child: _HubCard(kind: MetricKind.steps, summary: summary),
        ),
        Positioned(
          right: 16,
          bottom: size.height * 0.04,
          width: cardW,
          child: _HubCard(kind: MetricKind.calories, summary: summary),
        ),
      ],
    );
  }
}

class _Device extends StatelessWidget {
  const _Device({required this.tokens});

  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 224,
      padding: const EdgeInsets.only(top: 14),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tokens.glow.withValues(alpha: 0.9),
            tokens.glow.withValues(alpha: 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.glow.withValues(alpha: 0.55),
            blurRadius: 50,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const BrandMark(size: 34, showGlow: false),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.kind, required this.summary});

  final MetricKind kind;
  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return GlowCard(
      glow: true,
      padding: const EdgeInsets.all(14),
      onTap: () => MetricDetailScreen.open(context, kind),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  kind.title,
                  style: AppTypography.monoStyle(
                    12,
                    FontWeight.w400,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              MetricIllustration(name: kind.illustration, height: 38),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                kind.display(summary),
                style: AppTypography.monoStyle(
                  24,
                  FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  kind.unit,
                  style: AppTypography.monoStyle(
                    11,
                    FontWeight.w400,
                    color: tokens.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final anchors = [
      Offset(size.width * 0.28, size.height * 0.16),
      Offset(size.width * 0.72, size.height * 0.30),
      Offset(size.width * 0.28, size.height * 0.74),
      Offset(size.width * 0.72, size.height * 0.88),
    ];
    final line = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final dot = Paint()..color = color;
    for (final anchor in anchors) {
      final mid = Offset(anchor.dx, center.dy);
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(anchor.dx, anchor.dy);
      canvas.drawPath(path, line);
      canvas.drawCircle(anchor, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) => oldDelegate.color != color;
}
