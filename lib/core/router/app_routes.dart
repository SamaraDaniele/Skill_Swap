abstract final class AppRoutes {
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String setup = '/setup';
  static const String discover = '/discover';
  static const String matches = '/matches';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String chatPattern = '/chat/:matchId';
  static const String terms = '/terms';
  static const String consent = '/consent';

  static const String community = '/community';
  static const String newPost = '/community/new';
  static const String communitySearch = '/community/search';
  static const String saved = '/community/saved';
  static const String notifications = '/community/notifications';
  static const String postPattern = '/post/:postId';
  static const String editPostPattern = '/post/:postId/edit';
  static const String memberPattern = '/member/:uid';
  static const String followersPattern = '/member/:uid/followers';
  static const String followingPattern = '/member/:uid/following';

  static String chat(String matchId) => '/chat/$matchId';
  static String post(String postId) => '/post/$postId';
  static String editPost(String postId) => '/post/$postId/edit';
  static String member(String uid) => '/member/$uid';
  static String followers(String uid) => '/member/$uid/followers';
  static String following(String uid) => '/member/$uid/following';
  static String communitySearchFor(String query) =>
      Uri(path: communitySearch, queryParameters: {'q': query}).toString();

  static bool isDeepLink(String location) =>
      location.startsWith('/post/') || location.startsWith('/member/');
}
