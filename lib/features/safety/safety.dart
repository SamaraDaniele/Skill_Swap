import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/firebase_providers.dart';
import '../matches/matches.dart';

enum ReportReason {
  harassment,
  spam,
  inappropriate,
  fake,
  offensive,
  scam,
  other;

  String get id => name;
}

class SafetyRepository {
  const SafetyRepository(this._db);

  final FirebaseFirestore _db;

  static const int maxDetailsLength = 500;

  void _addBlock(WriteBatch batch, String me, String other) {
    batch.set(_db.collection(Collections.blocks).doc('${me}_$other'), {
      'blocker': me,
      'blocked': other,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _addClose(WriteBatch batch, String me, Match? match) {
    if (match == null || match.isClosed) return;
    batch.update(
      _db.collection(Collections.matches).doc(match.id),
      MatchRepository.closeData(me),
    );
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> _follows(
    String me,
    String other,
  ) async {
    final follows = _db.collection(Collections.follows);
    final refs = [follows.doc('${me}_$other'), follows.doc('${other}_$me')];
    final docs = await Future.wait(refs.map((ref) => ref.get()));
    return [
      for (final doc in docs)
        if (doc.exists) doc.reference,
    ];
  }

  Future<void> block({
    required String me,
    required String other,
    Match? match,
  }) => guard(() async {
    final follows = await _follows(me, other);
    final batch = _db.batch();
    _addBlock(batch, me, other);
    _addClose(batch, me, match);
    for (final ref in follows) {
      batch.delete(ref);
    }
    await batch.commit();
  });

  Future<void> reportContent({
    required String me,
    required String authorId,
    required String postId,
    required ReportReason reason,
    required String details,
    String? commentId,
  }) => guard(() {
    final trimmed = details.trim();
    return _db.collection(Collections.reports).doc().set({
      'reporterId': me,
      'reportedId': authorId,
      'reason': reason.id,
      'details': trimmed.length > maxDetailsLength
          ? trimmed.substring(0, maxDetailsLength)
          : trimmed,
      'targetType': commentId == null ? 'post' : 'comment',
      'postId': postId,
      'commentId': commentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  });

  Future<void> report({
    required String me,
    required String other,
    required ReportReason reason,
    required String details,
    Match? match,
  }) => guard(() async {
    final follows = await _follows(me, other);
    final trimmed = details.trim();
    final batch = _db.batch()
      ..set(_db.collection(Collections.reports).doc(), {
        'reporterId': me,
        'reportedId': other,
        'reason': reason.id,
        'details': trimmed.length > maxDetailsLength
            ? trimmed.substring(0, maxDetailsLength)
            : trimmed,
        'matchId': match?.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    _addBlock(batch, me, other);
    _addClose(batch, me, match);
    for (final ref in follows) {
      batch.delete(ref);
    }
    await batch.commit();
  });
}

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepository(ref.watch(firestoreProvider)),
);
