import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:skill_swap/core/error/failure.dart';
import 'package:skill_swap/features/discover/discover.dart';
import 'package:skill_swap/features/matches/matches.dart';
import 'package:skill_swap/features/profile/profile.dart';
import 'package:skill_swap/features/safety/safety.dart';

// The in-memory Firestore does not run security rules. Where the outcome
// depends on them (match creation), the test simulates the server's answer;
// the rules themselves are tested in firestore_rules_test/.
FirebaseException permissionDenied() =>
    FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');

void main() {
  late FakeFirebaseFirestore db;
  late DiscoverRepository discover;
  late ProfileRepository profiles;

  const me = UserProfile(
    id: 'me',
    name: 'Ana',
    bio: '',
    teach: ['excel'],
    learn: ['english'],
  );
  const best = UserProfile(
    id: 'best',
    name: 'Bia',
    bio: '',
    teach: ['english'],
    learn: ['excel'],
  );
  const partial = UserProfile(
    id: 'partial',
    name: 'Caio',
    bio: '',
    teach: ['english'],
    learn: ['guitar'],
  );
  const unrelated = UserProfile(
    id: 'unrelated',
    name: 'Davi',
    bio: '',
    teach: ['piano'],
    learn: ['excel'],
  );

  DocumentReference<Map<String, dynamic>> matchRef() =>
      db.collection('matches').doc(Match.pairId('me', 'best'));

  setUp(() async {
    db = FakeFirebaseFirestore();
    discover = DiscoverRepository(db);
    profiles = ProfileRepository(db);
    for (final p in [me, best, partial, unrelated]) {
      await profiles.save(p);
    }
  });

  test('candidates teach what I want, ranked by compatibility', () async {
    final result = await discover.fetchCandidates(me);
    expect(result.map((p) => p.id), ['best', 'partial']);
  });

  test('already swiped profiles are excluded', () async {
    await discover.swipe(me: me, target: best, liked: false);
    final result = await discover.fetchCandidates(me);
    expect(result.map((p) => p.id), ['partial']);
  });

  test('a skip records the like as false and never tries a match', () async {
    whenCalling(Invocation.method(#set, null))
        .on(matchRef())
        .thenThrow(Exception('must not be called'));
    final matched = await discover.swipe(me: me, target: best, liked: false);
    expect(matched, isFalse);
    final like = await db.collection('likes').doc('me_best').get();
    expect(like.data()?['liked'], isFalse);
  });

  test('like rejected by the rules (not mutual yet) is not a match', () async {
    whenCalling(Invocation.method(#set, null))
        .on(matchRef())
        .thenThrow(permissionDenied());

    final matched = await discover.swipe(me: me, target: best, liked: true);

    expect(matched, isFalse);
    expect((await db.collection('matches').get()).docs, isEmpty);
    final like = await db.collection('likes').doc('me_best').get();
    expect(like.data()?['liked'], isTrue);
  });

  test('like accepted by the rules creates a match without names', () async {
    final matched = await discover.swipe(me: me, target: best, liked: true);

    expect(matched, isTrue);
    final doc = await matchRef().get();
    expect(doc.data()?.keys, {
      'userIds',
      'status',
      'lastMessage',
      'lastMessageId',
      'createdAt',
      'lastMessageAt',
    });
    expect(doc.data()?['userIds'], ['best', 'me']);
  });

  test('match created by the other person at the same time counts', () async {
    await matchRef().set({
      'userIds': ['best', 'me'],
    });
    whenCalling(Invocation.method(#set, null))
        .on(matchRef())
        .thenThrow(permissionDenied());

    expect(await discover.swipe(me: me, target: best, liked: true), isTrue);
  });

  test('other errors are not hidden as "no match"', () async {
    whenCalling(Invocation.method(#set, null))
        .on(matchRef())
        .thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );

    await expectLater(
      discover.swipe(me: me, target: best, liked: true),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('sending a message links the preview to the real message', () async {
    await discover.swipe(me: me, target: best, liked: true);
    final repo = MatchRepository(db);
    final id = Match.pairId('me', 'best');

    await repo.sendMessage(matchId: id, senderId: 'me', text: '  Oi!  ');
    await repo.sendMessage(matchId: id, senderId: 'me', text: '   ');

    final messages = await repo.watchMessages(id).first;
    expect(messages.map((m) => m.text), ['Oi!']);
    final matchData = (await matchRef().get()).data()!;
    expect(matchData['lastMessage'], 'Oi!');
    expect(matchData['lastMessageId'], messages.single.id);
    final matches = await repo.watchMatches('best').first;
    expect(matches.single.otherUserId('best'), 'me');
  });

  test('unknown skill ids from the database are dropped', () {
    final profile = UserProfile.fromMap('x', {
      'name': 'X',
      'teach': ['excel', 'BUY CHEAP STUFF', 42],
      'learn': ['english', 'not-a-skill'],
    });
    expect(profile.teach, ['excel']);
    expect(profile.learn, ['english']);
  });

  group('[H1] safety', () {
    Future<Match> seedMatch({String status = 'active'}) async {
      await matchRef().set({
        'userIds': ['best', 'me'],
        'status': status,
        'lastMessage': null,
      });
      return Match.fromDoc(await matchRef().get());
    }

    test('profile creation also records consent', () async {
      const nova = UserProfile(
        id: 'nova',
        name: 'Nova',
        bio: '',
        teach: ['excel'],
        learn: ['english'],
      );
      await profiles.createWithConsent(nova);
      final consent = await db.doc('users/nova/private/consent').get();
      expect(consent.data()?['termsVersion'], ProfileRepository.termsVersion);
      expect(consent.data()?['adult'], isTrue);
      expect(await profiles.watchConsent('nova').first, isTrue);
      expect(await profiles.watchConsent('me').first, isFalse);
    });

    test('unmatch closes the match and it reads as closed', () async {
      await seedMatch();
      await MatchRepository(db).closeMatch(matchId: 'best_me', uid: 'me');
      final data = (await matchRef().get()).data()!;
      expect(data['status'], 'closed');
      expect(data['closedBy'], 'me');
      expect(Match.fromDoc(await matchRef().get()).isClosed, isTrue);
    });

    test('legacy matches without status read as active', () async {
      await matchRef().set({
        'userIds': ['best', 'me'],
      });
      expect(Match.fromDoc(await matchRef().get()).isClosed, isFalse);
    });

    test('block writes a private block and closes the match', () async {
      final match = await seedMatch();
      await SafetyRepository(db).block(me: 'me', other: 'best', match: match);
      final block = (await db.doc('blocks/me_best').get()).data()!;
      expect(block['blocker'], 'me');
      expect(block['blocked'], 'best');
      expect((await matchRef().get()).data()?['status'], 'closed');
    });

    test('block does not touch a match that is already closed', () async {
      final match = await seedMatch(status: 'closed');
      await SafetyRepository(db).block(me: 'me', other: 'best', match: match);
      expect((await matchRef().get()).data()?['closedBy'], isNull);
      expect((await db.doc('blocks/me_best').get()).exists, isTrue);
    });

    test('report sends the report, blocks and closes the match', () async {
      final match = await seedMatch();
      await SafetyRepository(db).report(
        me: 'me',
        other: 'best',
        reason: ReportReason.harassment,
        details: '  ${'x' * 600}  ',
        match: match,
      );
      final report = (await db.collection('reports').get()).docs.single;
      expect(report.data()['reporterId'], 'me');
      expect(report.data()['reportedId'], 'best');
      expect(report.data()['reason'], 'harassment');
      expect(report.data()['matchId'], 'best_me');
      expect(
        (report.data()['details'] as String).length,
        SafetyRepository.maxDetailsLength,
      );
      expect((await db.doc('blocks/me_best').get()).exists, isTrue);
      expect((await matchRef().get()).data()?['status'], 'closed');
    });

    test('report from discover (no match) blocks without a match id', () async {
      await SafetyRepository(db).report(
        me: 'me',
        other: 'partial',
        reason: ReportReason.spam,
        details: '',
      );
      final report = (await db.collection('reports').get()).docs.single;
      expect(report.data()['matchId'], isNull);
      expect((await db.doc('blocks/me_partial').get()).exists, isTrue);
    });

    test('blocked people disappear from discover', () async {
      await SafetyRepository(db).block(me: 'me', other: 'best');
      final result = await discover.fetchCandidates(me);
      expect(result.map((p) => p.id), ['partial']);
    });

    test('a closed match found after a denied create is not a match', () async {
      await seedMatch(status: 'closed');
      whenCalling(Invocation.method(#set, null))
          .on(matchRef())
          .thenThrow(permissionDenied());
      expect(await discover.swipe(me: me, target: best, liked: true), isFalse);
    });
  });

  group('[MS-10] candidates on a slow or offline network', () {
    QueryFetcher serverFails(String code) =>
        (query, options) => options.source == Source.server
        ? Future.error(FirebaseException(plugin: 'cloud_firestore', code: code))
        : query.get(options);

    test('server unreachable: cached candidates are still shown', () async {
      final offline = DiscoverRepository(db, fetch: serverFails('unavailable'));
      final result = await offline.fetchCandidates(me);
      expect(result.map((p) => p.id), ['best', 'partial']);
    });

    test('server unreachable and nothing cached: NetworkFailure, not an '
        'empty deck', () async {
      const loner = UserProfile(
        id: 'loner',
        name: 'Lu',
        bio: '',
        teach: [],
        learn: ['chemistry'],
      );
      final offline = DiscoverRepository(db, fetch: serverFails('unavailable'));
      await expectLater(
        offline.fetchCandidates(loner),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('server too slow: falls back to the cache', () async {
      final slow = DiscoverRepository(
        db,
        serverTimeout: const Duration(milliseconds: 50),
        fetch: (query, options) => options.source == Source.server
            ? Completer<QuerySnapshot<Map<String, dynamic>>>().future
            : query.get(options),
      );
      final result = await slow.fetchCandidates(me);
      expect(result.map((p) => p.id), ['best', 'partial']);
    });

    test('permission errors are not mistaken for offline', () async {
      final denied = DiscoverRepository(
        db,
        fetch: serverFails('permission-denied'),
      );
      await expectLater(
        denied.fetchCandidates(me),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('online with no candidates is a real empty deck', () async {
      const loner = UserProfile(
        id: 'loner',
        name: 'Lu',
        bio: '',
        teach: [],
        learn: ['chemistry'],
      );
      expect(await discover.fetchCandidates(loner), isEmpty);
    });
  });
}
