import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/user_profile_model.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<UserProfileModel?> profileStream(String uid) {
    return _firestore.collection(FirestorePaths.users).doc(uid).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) {
          return null;
        }

        return UserProfileModel.fromFirestore(snapshot);
      },
    );
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _ensureProfile(credential.user);

    return credential;
  }

  Future<UserCredential> createAccountWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;

    if (user != null && name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
      await user.reload();
    }

    await _ensureProfile(_firebaseAuth.currentUser ?? user);

    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!_googleSignIn.supportsAuthenticate()) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      final credential = await _firebaseAuth.signInWithProvider(provider);
      await _ensureProfile(credential.user);

      return credential;
    }

    final googleAccount = await _googleSignIn.authenticate();
    final googleAuth = googleAccount.authentication;

    if (googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an ID token.',
      );
    }

    final credential = await _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: googleAuth.idToken),
    );
    await _ensureProfile(credential.user);

    return credential;
  }

  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  Future<void> _ensureProfile(User? user) async {
    if (user == null) {
      return;
    }

    final reference = _firestore.collection(FirestorePaths.users).doc(user.uid);
    final snapshot = await reference.get();
    final profile = UserProfileModel.fromFirebaseUser(user);

    if (snapshot.exists) {
      await reference.set(profile.toUpdateJson(), SetOptions(merge: true));
      return;
    }

    await reference.set(profile.toCreateJson());
    await reference
        .collection(FirestorePaths.settings)
        .doc(FirestorePaths.preferences)
        .set({
          'heartRateMin': 50,
          'heartRateMax': 120,
          'spo2Min': 94,
          'dailyStepsGoal': 8000,
          'sleepTargetHours': 7.5,
          'notificationsEnabled': true,
          'darkMode': false,
        }, SetOptions(merge: true));
  }
}
