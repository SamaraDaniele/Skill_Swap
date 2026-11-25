import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

abstract final class Collections {
  static const String users = 'users';
  static const String likes = 'likes';
  static const String matches = 'matches';
  static const String messages = 'messages';
  static const String blocks = 'blocks';
  static const String reports = 'reports';
  static const String posts = 'posts';
  static const String media = 'media';

  static const String video = 'video';
  static const String postLikes = 'likes';
  static const String comments = 'comments';
  static const String follows = 'follows';
  static const String saved = 'saved';
  static const String notifications = 'notifications';
  static const String rateLimits = 'rateLimits';
}
