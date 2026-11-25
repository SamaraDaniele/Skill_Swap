abstract final class PostLinks {
  static const String scheme = 'skillswap';
  static const String host = 'app';

  static final RegExp _pattern = RegExp(
    r'skillswap://app/post/([A-Za-z0-9_]{1,80})',
  );

  static String forPost(String postId) => '$scheme://$host/post/$postId';

  static String? findPostId(String text) => _pattern.firstMatch(text)?.group(1);
}
