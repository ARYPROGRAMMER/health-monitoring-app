import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/auth_error_mapper.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns session authentication: subscribes to Firebase auth changes and runs
/// sign-in / sign-up / Google / sign-out actions, mapping failures to messages.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState()) {
    on<AuthUserChanged>(_onUserChanged);
    on<AuthEmailSignInRequested>(_onEmailSignIn);
    on<AuthEmailSignUpRequested>(_onEmailSignUp);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthSignOutRequested>(_onSignOut);

    _subscription = _repository.authStateChanges().listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<User?> _subscription;

  Future<String?> idToken() async {
    final user = _repository.currentUser;
    if (user == null) return null;
    try {
      return (await user.getIdTokenResult(true)).token;
    } catch (_) {
      return null;
    }
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        status: event.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: event.user,
        clearUser: event.user == null,
        action: AuthAction.idle,
        clearError: true,
      ),
    );
  }

  Future<void> _run(Emitter<AuthState> emit, Future<void> Function() task) async {
    emit(state.copyWith(action: AuthAction.submitting, clearError: true));
    try {
      await task();
      emit(state.copyWith(action: AuthAction.idle));
    } catch (error) {
      emit(
        state.copyWith(
          action: AuthAction.failure,
          errorMessage: AuthErrorMapper.message(error),
        ),
      );
    }
  }

  Future<void> _onEmailSignIn(
    AuthEmailSignInRequested event,
    Emitter<AuthState> emit,
  ) => _run(
    emit,
    () => _repository.signInWithEmail(
      email: event.email,
      password: event.password,
    ),
  );

  Future<void> _onEmailSignUp(
    AuthEmailSignUpRequested event,
    Emitter<AuthState> emit,
  ) => _run(
    emit,
    () => _repository.createAccountWithEmail(
      name: event.name,
      email: event.email,
      password: event.password,
    ),
  );

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) => _run(emit, _repository.signInWithGoogle);

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) => _run(emit, _repository.signOut);

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
