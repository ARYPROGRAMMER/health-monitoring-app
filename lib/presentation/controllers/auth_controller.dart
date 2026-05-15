import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/auth_error_mapper.dart';
import '../../data/providers/app_providers.dart';

final authActionProvider = NotifierProvider<AuthController, AsyncValue<void>>(
  AuthController.new,
);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _run(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password),
    );
  }

  Future<void> createAccountWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await _run(
      () => ref
          .read(authRepositoryProvider)
          .createAccountWithEmail(name: name, email: email, password: password),
    );
  }

  Future<void> signInWithGoogle() async {
    await _run(() => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  Future<void> signOut() async {
    await _run(() => ref.read(authRepositoryProvider).signOut());
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();

    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(AuthErrorMapper.message(error), stackTrace);
    }
  }
}
