import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/firebase_providers.dart';
import '../auth/auth_repository.dart';

class Match {
  const Match({
    required this.id,
    required this.userIds,
    required this.lastMessage,
    required this.lastMessageAt,
    this.isClosed = false,
  });

  factory Match.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Match(
      id: doc.id,
      userIds: (data['userIds'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      isClosed: data['status'] == 'closed',
    );
  }

  final String id;
  final List<String> userIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  final bool isClosed;

  String otherUserId(String me) =>
      userIds.firstWhere((id) => id != me, orElse: () => me);

  static List<String> sortedPair(String a, String b) =>
      a.compareTo(b) <= 0 ? [a, b] : [b, a];

  static String pairId(String a, String b) => sortedPair(a, b).join('_');
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      sentAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
}

class MatchRepository {
  const MatchRepository(this._db);

  final FirebaseFirestore _db;

  static const int maxMessageLength = 2000;
  static const int _messageLimit = 100;

  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection(Collections.matches);

  Stream<List<Match>> watchMatches(String uid) =>
      _matches.where('userIds', arrayContains: uid).snapshots().map((snap) {
        final list = snap.docs.map(Match.fromDoc).toList();
        final epoch = DateTime.fromMillisecondsSinceEpoch(0);
        list.sort(
          (a, b) =>
              (b.lastMessageAt ?? epoch).compareTo(a.lastMessageAt ?? epoch),
        );
        return list;
      }).mapFailures();

  Stream<List<ChatMessage>> watchMessages(String matchId) => _matches
      .doc(matchId)
      .collection(Collections.messages)
      .orderBy('createdAt', descending: true)
      .limit(_messageLimit)
      .snapshots()
      .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList())
      .mapFailures();

  static Map<String, Object?> closeData(String uid) => {
    'status': 'closed',
    'closedBy': uid,
    'closedAt': FieldValue.serverTimestamp(),
  };

  Future<void> closeMatch({required String matchId, required String uid}) =>
      guard(() => _matches.doc(matchId).update(closeData(uid)));

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) => guard(() {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();
    final body = trimmed.length > maxMessageLength
        ? trimmed.substring(0, maxMessageLength)
        : trimmed;
    final matchRef = _matches.doc(matchId);
    final messageRef = matchRef.collection(Collections.messages).doc();
    final batch = _db.batch()
      ..set(messageRef, {
        'senderId': senderId,
        'text': body,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(matchRef, {
        'lastMessage': body,
        'lastMessageId': messageRef.id,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    return batch.commit();
  });
}

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(firestoreProvider)),
);

final matchesProvider = StreamProvider.autoDispose<List<Match>>((ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return Stream.value(const []);
  return ref.watch(matchRepositoryProvider).watchMatches(uid);
});

final unstartedChatsCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(
    matchesProvider.select(
      (matches) =>
          matches.value
              ?.where((m) => !m.isClosed && m.lastMessage == null)
              .length ??
          0,
    ),
  ),
);

final messagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>(
      (ref, matchId) =>
          ref.watch(matchRepositoryProvider).watchMessages(matchId),
    );
