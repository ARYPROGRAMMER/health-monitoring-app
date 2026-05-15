import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_profile_model.dart';
import '../repositories/auth_repository.dart';
import '../services/backend_api_client.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn.instance,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProfileProvider = StreamProvider<UserProfileModel?>((ref) {
  return ref
      .watch(authStateProvider)
      .when(
        data: (user) {
          if (user == null) {
            return Stream<UserProfileModel?>.value(null);
          }

          return ref.watch(authRepositoryProvider).profileStream(user.uid);
        },
        loading: () => Stream<UserProfileModel?>.value(null),
        error: (error, stackTrace) => Stream<UserProfileModel?>.value(null),
      );
});

final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  return BackendApiClient(firebaseAuth: ref.watch(firebaseAuthProvider));
});
