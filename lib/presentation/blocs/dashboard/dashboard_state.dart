part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.summary,
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardSummaryModel? summary;
  final String? errorMessage;

  bool get hasVitals => summary?.hasVitals ?? false;
  bool get isOffline => summary?.isOffline ?? false;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSummaryModel? summary,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, summary, errorMessage];
}
