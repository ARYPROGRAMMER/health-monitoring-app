part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

enum AuthAction { idle, submitting, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.action = AuthAction.idle,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final AuthAction action;
  final String? errorMessage;

  bool get isSubmitting => action == AuthAction.submitting;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
    AuthAction? action,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      action: action ?? this.action,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user?.uid, action, errorMessage];
}
