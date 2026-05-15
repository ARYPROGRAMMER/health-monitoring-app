import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_monitoring_app/data/models/user_profile_model.dart';

void main() {
  test('serializes user profile creation payload', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);
    final profile = UserProfileModel(
      uid: 'user-1',
      displayName: 'Arya',
      email: 'arya@example.com',
      photoUrl: null,
      providerIds: const ['password'],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final json = profile.toCreateJson();

    expect(json['uid'], 'user-1');
    expect(json['displayName'], 'Arya');
    expect(json['email'], 'arya@example.com');
    expect(json['providerIds'], const ['password']);
    expect(
      (json['createdAt'] as Timestamp).toDate().millisecondsSinceEpoch,
      createdAt.millisecondsSinceEpoch,
    );
    expect(
      (json['updatedAt'] as Timestamp).toDate().millisecondsSinceEpoch,
      updatedAt.millisecondsSinceEpoch,
    );
  });
}
