import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/firebase_providers.dart';
import '../auth/auth_repository.dart';
import 'profile_photo.dart';
import 'skills.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.bio,
    required this.teach,
    required this.learn,
    this.photo,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) =>
      UserProfile(
        id: id,
        name: map['name'] as String? ?? '',
        bio: map['bio'] as String? ?? '',
        teach: _stringList(map['teach']),
        learn: _stringList(map['learn']),
        photo: _photo(map['photo']),
      );

  final String id;
  final String name;
  final String bio;

  final List<String> teach;

  final List<String> learn;

  final Uint8List? photo;

  Map<String, Object?> toMap() => {
    'name': name,
    'bio': bio,
    'teach': teach,
    'learn': learn,
    if (photo case final bytes?) 'photo': Blob(bytes),
  };

  static List<String> _stringList(Object? value) => value is List
      ? value.whereType<String>().where(Skills.all.contains).toList()
      : const [];

  static Uint8List? _photo(Object? value) => switch (value) {
    Blob(:final bytes) when ProfilePhoto.isAcceptable(bytes) => bytes,
    _ => null,
  };
}

abstract final class Compatibility {
  static int score(UserProfile me, UserProfile other) {
    double ratio(List<String> offered, List<String> wanted) {
      if (wanted.isEmpty) return 0;
      final offeredSet = offered.toSet();
      return wanted.where(offeredSet.contains).length / wanted.length;
    }

    final received = ratio(other.teach, me.learn);
    final given = ratio(me.teach, other.learn);
    return ((received + given) / 2 * 100).round();
  }
}

class ProfileRepository {
  const ProfileRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(Collections.users);

  Stream<UserProfile?> watch(String uid) =>
      _users.doc(uid).snapshots().map((doc) {
        final data = doc.data();
        return data == null ? null : UserProfile.fromMap(doc.id, data);
      }).mapFailures();

  static const int termsVersion = 1;

  DocumentReference<Map<String, dynamic>> _consent(String uid) =>
      _users.doc(uid).collection('private').doc('consent');

  Map<String, Object?> _consentData() => {
    'termsVersion': termsVersion,
    'adult': true,
    'acceptedAt': FieldValue.serverTimestamp(),
  };

  Map<String, Object?> _profileData(UserProfile profile) => {
    ...profile.toMap(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Future<void> save(UserProfile profile, {bool removePhoto = false}) => guard(
    () => _users.doc(profile.id).set({
      ..._profileData(profile),
      if (removePhoto && profile.photo == null) 'photo': FieldValue.delete(),
    }, SetOptions(merge: true)),
  );

  Future<void> createWithConsent(UserProfile profile) => guard(
    () =>
        (_db.batch()
              ..set(_consent(profile.id), _consentData())
              ..set(_users.doc(profile.id), _profileData(profile)))
            .commit(),
  );

  Future<void> acceptConsent(String uid) =>
      guard(() => _consent(uid).set(_consentData()));

  Stream<bool> watchConsent(String uid) =>
      _consent(uid)
          .snapshots()
          .map((doc) => doc.data()?['termsVersion'] == termsVersion)
          .mapFailures();
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(firestoreProvider)),
);

final currentProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watch(uid);
});

final consentProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return Stream.value(false);
  return ref.watch(profileRepositoryProvider).watchConsent(uid);
});

final userProfileProvider = StreamProvider.autoDispose
    .family<UserProfile?, String>(
      (ref, uid) => ref.watch(profileRepositoryProvider).watch(uid),
    );
