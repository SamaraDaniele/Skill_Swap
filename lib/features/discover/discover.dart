import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/firebase_providers.dart';
import '../matches/matches.dart';
import '../profile/profile.dart';

typedef QueryFetcher = Future<QuerySnapshot<Map<String, dynamic>>> Function(
  Query<Map<String, dynamic>> query,
  GetOptions options,
);

class DiscoverRepository {
  DiscoverRepository(this._db, {QueryFetcher? fetch, Duration? serverTimeout})
    : _fetch = fetch ?? ((query, options) => query.get(options)),
      _serverTimeout = serverTimeout ?? const Duration(seconds: 12);

  final FirebaseFirestore _db;
  final QueryFetcher _fetch;
  final Duration _serverTimeout;

  static const int _candidateLimit = 50;

  Future<QuerySnapshot<Map<String, dynamic>>> _getPreferServer(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await _fetch(
        query,
        const GetOptions(source: Source.server),
      ).timeout(_serverTimeout);
    } on TimeoutException {
      return _fetch(query, const GetOptions(source: Source.cache));
    } on FirebaseException catch (error) {
      if (error.code != 'unavailable' && error.code != 'deadline-exceeded') {
        rethrow;
      }
      return _fetch(query, const GetOptions(source: Source.cache));
    }
  }

  Future<List<UserProfile>> fetchCandidates(UserProfile me) => guard(() async {
    Query<Map<String, dynamic>> query = _db.collection(Collections.users);
    if (me.learn.isNotEmpty) {
      query = query.where('teach', arrayContainsAny: me.learn.take(30));
    }
    final results = await Future.wait([
      _getPreferServer(query.limit(_candidateLimit)),
      _getPreferServer(
        _db.collection(Collections.likes).where('from', isEqualTo: me.id),
      ),
      _getPreferServer(
        _db.collection(Collections.blocks).where('blocker', isEqualTo: me.id),
      ),
    ]);
    final fromCache = results.any((r) => r.metadata.isFromCache);
    final users = results[0];
    final seen = {
      ...results[1].docs.map((d) => d.data()['to']),
      ...results[2].docs.map((d) => d.data()['blocked']),
    };

    final candidates = users.docs
        .where((d) => d.id != me.id && !seen.contains(d.id))
        .map((d) => UserProfile.fromMap(d.id, d.data()))
        .toList();
    final scores = {
      for (final c in candidates) c.id: Compatibility.score(me, c),
    };
    candidates.sort((a, b) => scores[b.id]!.compareTo(scores[a.id]!));
    if (candidates.isEmpty && fromCache) throw const NetworkFailure();
    return candidates;
  });

  Future<bool> swipe({
    required UserProfile me,
    required UserProfile target,
    required bool liked,
  }) => guard(() async {
    final likes = _db.collection(Collections.likes);
    await likes.doc('${me.id}_${target.id}').set({
      'from': me.id,
      'to': target.id,
      'liked': liked,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!liked) return false;

    final matchRef = _db
        .collection(Collections.matches)
        .doc(Match.pairId(me.id, target.id));
    try {
      await matchRef.set({
        'userIds': Match.sortedPair(me.id, target.id),
        'status': 'active',
        'lastMessage': null,
        'lastMessageId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      final existing = await matchRef.get();
      return existing.exists && existing.data()?['status'] != 'closed';
    }
  });
}

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepository(ref.watch(firestoreProvider)),
);

final discoverControllerProvider =
    AsyncNotifierProvider.autoDispose<DiscoverController, List<UserProfile>>(
      DiscoverController.new,
    );

class DiscoverController extends AsyncNotifier<List<UserProfile>> {
  @override
  Future<List<UserProfile>> build() async {
    final me = await ref.watch(currentProfileProvider.future);
    if (me == null) return const [];
    return ref.read(discoverRepositoryProvider).fetchCandidates(me);
  }

  void remove(UserProfile target) {
    final deck = state.value;
    if (deck == null) return;
    state = AsyncData(deck.where((p) => p.id != target.id).toList());
  }

  void restore(UserProfile target) {
    final deck = state.value;
    if (deck == null || deck.any((p) => p.id == target.id)) return;
    state = AsyncData([target, ...deck]);
  }

  Future<bool> swipe(
    UserProfile target, {
    required bool liked,
    bool Function()? topIsBusy,
  }) async {
    final me = ref.read(currentProfileProvider).value;
    final deck = state.value;
    if (me == null || deck == null) return false;

    state = AsyncData(deck.where((p) => p.id != target.id).toList());
    try {
      return await ref
          .read(discoverRepositoryProvider)
          .swipe(me: me, target: target, liked: liked);
    } catch (_) {
      if (ref.mounted) {
        final current = [...?state.value];
        if (!current.any((p) => p.id == target.id)) {
          final busy = current.isNotEmpty && (topIsBusy?.call() ?? false);
          current.insert(busy ? 1 : 0, target);
          state = AsyncData(current);
        }
      }
      rethrow;
    }
  }
}
