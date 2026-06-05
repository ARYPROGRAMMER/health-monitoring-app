import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/user_profile_model.dart';
import '../../../data/repositories/auth_repository.dart';

class ProfileState extends Equatable {
  const ProfileState({this.profile, this.isLoading = false});

  final UserProfileModel? profile;
  final bool isLoading;

  String get displayName => profile?.displayName ?? 'Stealthera Member';
  String get firstName => displayName.split(' ').first;

  @override
  List<Object?> get props => [
    profile?.uid,
    profile?.displayName,
    profile?.email,
    profile?.photoUrl,
    isLoading,
  ];
}

/// Streams the signed-in user's Firestore profile. Driven from the widget tree
/// (a [BlocListener] on the auth state) to keep blocs decoupled.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final AuthRepository _repository;
  StreamSubscription<UserProfileModel?>? _subscription;

  void watch(String uid) {
    _subscription?.cancel();
    emit(const ProfileState(isLoading: true));
    _subscription = _repository.profileStream(uid).listen(
      (profile) => emit(ProfileState(profile: profile)),
      onError: (_) => emit(const ProfileState()),
    );
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    emit(const ProfileState());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
