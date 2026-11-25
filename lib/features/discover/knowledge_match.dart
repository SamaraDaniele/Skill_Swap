import '../profile/profile.dart';

enum KnowledgeMatchType { teach, learn, exchange }

class KnowledgeMatch {
  const KnowledgeMatch._({
    required this.type,
    required this.iCanTeach,
    required this.iCanLearn,
  });

  final List<String> iCanTeach;

  final List<String> iCanLearn;

  final KnowledgeMatchType type;

  static KnowledgeMatch? between(UserProfile me, UserProfile other) {
    final theyWant = other.learn.toSet();
    final iWant = me.learn.toSet();
    final iCanTeach = me.teach.where(theyWant.contains).toList();
    final iCanLearn = other.teach.where(iWant.contains).toList();
    final type = switch ((iCanTeach.isNotEmpty, iCanLearn.isNotEmpty)) {
      (true, true) => KnowledgeMatchType.exchange,
      (true, false) => KnowledgeMatchType.teach,
      (false, true) => KnowledgeMatchType.learn,
      (false, false) => null,
    };
    if (type == null) return null;
    return KnowledgeMatch._(
      type: type,
      iCanTeach: iCanTeach,
      iCanLearn: iCanLearn,
    );
  }
}
