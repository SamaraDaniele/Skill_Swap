import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../profile/skills.dart';
import 'post_media.dart';
import 'post_video.dart';

abstract final class CommunityLimits {
  static const int maxDescription = 2000;
  static const int maxImages = 5;
  static const int maxSkills = 5;
  static const int maxTags = 10;
  static const int maxTagLength = 30;
  static const int maxKeywords = 40;
  static const int maxComment = 1000;

  static const Duration postCooldown = Duration(seconds: 30);
  static const Duration commentCooldown = Duration(seconds: 3);

  static const Duration videoCooldown = Duration(hours: 1);

  static const int feedPageSize = 10;
  static const int commentPageSize = 20;

  static const int maxFollowingInFeed = 30;
}

enum PostType {
  project,
  tip,

  knowledge,
  question,
  achievement,
  work;

  String get id => name;

  static PostType fromId(Object? id) =>
      values.firstWhere((t) => t.name == id, orElse: () => PostType.work);
}

DateTime _date(Object? value) =>
    (value as Timestamp?)?.toDate() ?? DateTime.now();

String? _string(Object? value) => value is String ? value : null;

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.description,
    required this.type,
    required this.skillIds,
    required this.tags,
    required this.mediaCount,
    required this.aspectRatios,
    required this.createdAt,
    this.updatedAt,
    this.thumb,
    this.video,
  });

  factory CommunityPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final mediaCount = switch (data['mediaCount']) {
      final int n => n.clamp(0, CommunityLimits.maxImages),
      _ => 0,
    };
    final ratios = (data['aspectRatios'] as List? ?? const [])
        .whereType<num>()
        .map((r) => r.toDouble())
        .toList();
    final description = _string(data['description']) ?? '';
    final video = mediaCount == 1
        ? PostVideoInfo.tryParse(data['video'])
        : null;
    return CommunityPost(
      id: doc.id,
      authorId: _string(data['authorId']) ?? '',
      description: description.length > CommunityLimits.maxDescription
          ? description.substring(0, CommunityLimits.maxDescription)
          : description,
      type: PostType.fromId(data['type']),
      skillIds: (data['skillIds'] as List? ?? const [])
          .whereType<String>()
          .where(Skills.all.contains)
          .take(CommunityLimits.maxSkills)
          .toList(),
      tags: (data['tags'] as List? ?? const [])
          .whereType<String>()
          .where(CommunityText.isValidTag)
          .take(CommunityLimits.maxTags)
          .toList(),
      mediaCount: mediaCount,
      aspectRatios: [
        for (var i = 0; i < mediaCount; i++)
          PostImage.clampAspect(i < ratios.length ? ratios[i] : 1),
      ],
      createdAt: _date(data['createdAt']),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      thumb: switch (data['thumb']) {
        Blob(:final bytes) when PostImage.isAcceptableThumb(bytes) => bytes,
        _ => null,
      },
      video: video,
    );
  }

  final String id;
  final String authorId;
  final String description;
  final PostType type;

  final List<String> skillIds;

  final List<String> tags;

  final int mediaCount;

  final List<double> aspectRatios;

  final DateTime createdAt;
  final DateTime? updatedAt;

  final Uint8List? thumb;

  final PostVideoInfo? video;

  bool get isEdited =>
      updatedAt != null && updatedAt!.difference(createdAt).inSeconds > 5;

  CommunityPost copyWith({
    String? description,
    PostType? type,
    List<String>? skillIds,
    List<String>? tags,
  }) => CommunityPost(
    id: id,
    authorId: authorId,
    description: description ?? this.description,
    type: type ?? this.type,
    skillIds: skillIds ?? this.skillIds,
    tags: tags ?? this.tags,
    mediaCount: mediaCount,
    aspectRatios: aspectRatios,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    thumb: thumb,
    video: video,
  );
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.parentId,
  });

  factory CommunityComment.fromDoc(
    String postId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final text = _string(data['text']) ?? '';
    return CommunityComment(
      id: doc.id,
      postId: postId,
      authorId: _string(data['authorId']) ?? '',
      text: text.length > CommunityLimits.maxComment
          ? text.substring(0, CommunityLimits.maxComment)
          : text,
      parentId: _string(data['parentId']),
      createdAt: _date(data['createdAt']),
    );
  }

  final String id;
  final String postId;
  final String authorId;
  final String text;
  final String? parentId;
  final DateTime createdAt;

  bool get isReply => parentId != null;
}

enum NotificationType {
  like,
  comment,
  reply,
  follow,
  learn;

  static NotificationType? fromId(Object? id) =>
      values.where((t) => t.name == id).firstOrNull;
}

class CommunityNotification {
  const CommunityNotification({
    required this.id,
    required this.type,
    required this.actorId,
    required this.read,
    required this.createdAt,
    this.postId,
    this.commentId,
  });

  static CommunityNotification? fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final type = NotificationType.fromId(data['type']);
    final actorId = _string(data['actorId']);
    if (type == null || actorId == null) return null;
    return CommunityNotification(
      id: doc.id,
      type: type,
      actorId: actorId,
      postId: _string(data['postId']),
      commentId: _string(data['commentId']),
      read: data['read'] == true,
      createdAt: _date(data['createdAt']),
    );
  }

  final String id;
  final NotificationType type;
  final String actorId;
  final String? postId;
  final String? commentId;
  final bool read;
  final DateTime createdAt;
}

class PostDraft {
  const PostDraft({
    required this.description,
    required this.type,
    required this.skillIds,
    required this.tags,
    this.images = const [],
    this.video,
  });

  final String description;
  final PostType type;
  final List<String> skillIds;
  final List<String> tags;
  final List<PreparedImage> images;

  final PreparedVideo? video;

  List<PreparedImage> get storedImages =>
      video != null ? [video!.poster] : images;

  bool get isEmpty =>
      description.trim().isEmpty && images.isEmpty && video == null;
}

abstract final class CommunityText {
  static final RegExp _tag = RegExp(r'^[\p{L}\p{N}_]{1,30}$', unicode: true);
  static final RegExp _separators = RegExp(r'[\s,;#]+');
  static final RegExp _word = RegExp(r'[\p{L}\p{N}_]+', unicode: true);

  static bool isValidTag(String tag) => _tag.hasMatch(tag);

  static List<String> parseTags(String input) {
    final seen = <String>{};
    final tags = <String>[];
    for (final raw in input.split(_separators)) {
      if (raw.isEmpty || !isValidTag(raw)) continue;
      if (seen.add(normalize(raw))) tags.add(raw);
      if (tags.length == CommunityLimits.maxTags) break;
    }
    return tags;
  }

  static const Map<String, String> _accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  static String normalize(String value) {
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  static List<String> keywords({
    required String description,
    required List<String> tags,
    required List<String> skillIds,
  }) {
    final result = <String>{};
    void add(String word) {
      final w = normalize(word);
      if (w.length >= 2 && w.length <= CommunityLimits.maxTagLength) {
        result.add(w);
      }
    }

    tags.forEach(add);
    skillIds.forEach(add);
    for (final match in _word.allMatches(description)) {
      if (result.length >= CommunityLimits.maxKeywords) break;
      add(match.group(0)!);
    }
    return result.take(CommunityLimits.maxKeywords).toList();
  }

  static String? searchKeyword(String term) {
    final match = _word.firstMatch(term);
    if (match == null) return null;
    final word = normalize(match.group(0)!);
    return word.length >= 2 ? word : null;
  }
}
