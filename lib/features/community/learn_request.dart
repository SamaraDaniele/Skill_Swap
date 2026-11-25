import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/firebase_providers.dart';
import '../auth/auth_repository.dart';
import '../discover/discover.dart';
import '../matches/matches.dart';
import '../profile/profile.dart';
import 'community_providers.dart';

sealed class LearnStatus {
  const LearnStatus();
}

final class LearnSelf extends LearnStatus {
  const LearnSelf();
}

final class LearnUnavailable extends LearnStatus {
  const LearnUnavailable();
}

final class LearnAvailable extends LearnStatus {
  const LearnAvailable();
}

final class LearnPending extends LearnStatus {
  const LearnPending();
}

final class LearnMatched extends LearnStatus {
  const LearnMatched(this.matchId);

  final String matchId;
}

final learnStatusProvider = FutureProvider.autoDispose
    .family<LearnStatus, String>((ref, otherId) async {
      final me = ref.watch(authStateProvider).value;
      if (me == null) return const LearnUnavailable();
      if (me == otherId) return const LearnSelf();
      final blocked = await ref.watch(blockedIdsProvider.future);
      if (blocked.contains(otherId)) return const LearnUnavailable();

      final matchId = Match.pairId(me, otherId);
      final matchState = await ref.watch(
        matchesProvider.selectAsync(
          (matches) => switch (matches.where((m) => m.id == matchId)) {
            final found when found.isEmpty => 'none',
            final found => found.first.isClosed ? 'closed' : 'active',
          },
        ),
      );
      switch (matchState) {
        case 'active':
          return LearnMatched(matchId);
        case 'closed':
          return const LearnUnavailable();
      }
      final liked = await ref.watch(myInterestProvider(otherId).future);
      return liked ? const LearnPending() : const LearnAvailable();
    }, retry: communityRetry);

final myInterestProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  otherId,
) async {
  cacheFor(ref, const Duration(minutes: 5));
  final me = ref.watch(authStateProvider).value;
  if (me == null) return false;
  final like = await guard(
    () => ref
        .read(firestoreProvider)
        .collection(Collections.likes)
        .doc('${me}_$otherId')
        .get(),
  );
  return like.data()?['liked'] == true;
}, retry: communityRetry);

Future<bool> sendLearnRequest(
  WidgetRef ref, {
  required UserProfile author,
  String? postId,
}) async {
  final me = ref.read(currentProfileProvider).value;
  if (me == null || me.id == author.id) throw const PermissionFailure();
  final status = await ref.read(learnStatusProvider(author.id).future);
  if (status is! LearnAvailable) return status is LearnMatched;

  final matched = await ref
      .read(discoverRepositoryProvider)
      .swipe(me: me, target: author, liked: true);
  await ref
      .read(socialRepositoryProvider)
      .notifyLearnRequest(uid: me.id, authorId: author.id, postId: postId);
  if (ref.read(discoverControllerProvider.exists)) {
    ref.read(discoverControllerProvider.notifier).remove(author);
  }
  ref.invalidate(myInterestProvider(author.id));
  return matched;
}

List<String> teachableSkills(UserProfile author, List<String> postSkills) =>
    postSkills.where(author.teach.contains).toList();

Future<Match?> findMatch(
  ProviderContainer container,
  String me,
  String other,
) async {
  final matches = container.read(matchesProvider).value ?? const <Match>[];
  final id = Match.pairId(me, other);
  final known = matches.where((m) => m.id == id).firstOrNull;
  if (known != null) return known;
  try {
    final doc = await container
        .read(firestoreProvider)
        .collection(Collections.matches)
        .doc(id)
        .get();
    return doc.exists ? Match.fromDoc(doc) : null;
  } on FirebaseException {
    return null;
  }
}
