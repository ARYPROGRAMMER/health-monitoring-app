import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.providerIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final List<String> providerIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfileModel.fromFirebaseUser(User user) {
    final timestamp = DateTime.now();

    return UserProfileModel(
      uid: user.uid,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Stealthera Member',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      providerIds: user.providerData
          .map((provider) => provider.providerId)
          .toList(),
      createdAt: user.metadata.creationTime ?? timestamp,
      updatedAt: timestamp,
    );
  }

  factory UserProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return UserProfileModel(
      uid: data['uid'] as String? ?? snapshot.id,
      displayName: data['displayName'] as String? ?? 'Stealthera Member',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      providerIds: List<String>.from(data['providerIds'] as List? ?? const []),
      createdAt: _dateFromValue(data['createdAt']),
      updatedAt: _dateFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'providerIds': providerIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'providerIds': providerIds,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _dateFromValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
