import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_swap/core/firebase_providers.dart';
import 'package:skill_swap/features/community/community_providers.dart';
import 'package:skill_swap/features/community/community_repository.dart';

/// The next page waits for [gate].
class _SlowNextPage extends CommunityRepository {
  _SlowNextPage(super.db);

  final gate = Completer<void>();

  @override
  Future<PostPage> fetchPage(
    PostQuery query, {
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int limit = 10,
  }) async {
    if (cursor != null) await gate.future;
    return super.fetchPage(query, cursor: cursor, limit: limit);
  }
}

void main() {
  test('a post removed while the next page loads stays removed', () async {
    final db = FakeFirebaseFirestore();
    for (var i = 0; i < 12; i++) {
      await db.doc('posts/p$i').set({
        'authorId': 'bia',
        'description': 'post $i',
        'type': 'tip',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000 * i),
      });
    }
    final repo = _SlowNextPage(db);
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        communityRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    final provider = postListProvider(PostQuery.forYou);
    container.listen(provider, (_, _) {});
    final first = await container.read(provider.future);
    expect(first.posts, hasLength(10));

    final notifier = container.read(provider.notifier);
    final loading = notifier.loadMore();
    notifier.remove('p11');
    repo.gate.complete();
    await loading;

    final ids = container.read(provider).value!.posts.map((p) => p.id);
    expect(ids, isNot(contains('p11')));
    expect(ids, containsAll(['p1', 'p0']));
    expect(container.read(provider).value!.hasMore, isFalse);
  });
}
