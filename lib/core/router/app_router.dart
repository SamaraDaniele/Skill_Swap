import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/auth_repository.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/community/presentation/community_search_screen.dart';
import '../../features/community/presentation/member_profile_screen.dart';
import '../../features/community/presentation/notifications_screen.dart';
import '../../features/community/presentation/post_composer_screen.dart';
import '../../features/community/presentation/post_detail_screen.dart';
import '../../features/community/presentation/saved_posts_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/matches/chat_screen.dart';
import '../../features/matches/matches.dart';
import '../../features/matches/matches_screen.dart';
import '../../features/profile/profile.dart';
import '../../features/profile/profile_form_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/safety/terms_screens.dart';
import '../l10n/l10n.dart';
import '../widgets/app_widgets.dart';
import '../widgets/line_icons.dart';
import '../widgets/neon_nav_bar.dart';
import 'app_routes.dart';

String? resolveRedirect({
  required AsyncValue<String?> auth,
  required AsyncValue<UserProfile?> profile,
  required AsyncValue<bool> consent,
  required String location,
}) {
  String? goTo(String target) => location == target ? null : target;

  if (location == AppRoutes.terms) return null;
  if (!auth.hasValue) return goTo(AppRoutes.splash);
  if (auth.value == null) return goTo(AppRoutes.signIn);
  if (!profile.hasValue || profile.isLoading) return goTo(AppRoutes.splash);
  if (profile.value == null) return goTo(AppRoutes.setup);
  if (!consent.hasValue || consent.isLoading) return goTo(AppRoutes.splash);
  if (consent.value != true) return goTo(AppRoutes.consent);
  const entryRoutes = {
    AppRoutes.splash,
    AppRoutes.signIn,
    AppRoutes.setup,
    AppRoutes.consent,
  };
  return entryRoutes.contains(location) ? AppRoutes.discover : null;
}

class DeepLinkMemory {
  String? _pending;

  String? apply(
    String? target, {
    required String location,
    required String uri,
  }) {
    if (target != null && AppRoutes.isDeepLink(location)) {
      _pending = uri;
      return target;
    }
    final pending = _pending;
    if (target == AppRoutes.discover && pending != null) {
      _pending = null;
      return pending;
    }
    return target;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final deepLinks = DeepLinkMemory();
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authStateProvider, (_, _) => refresh.value++)
    ..listen(currentProfileProvider, (_, _) => refresh.value++)
    ..listen(consentProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => deepLinks.apply(
      resolveRedirect(
        auth: ref.read(authStateProvider),
        profile: ref.read(currentProfileProvider),
        consent: ref.read(consentProvider),
        location: state.matchedLocation,
      ),
      location: state.matchedLocation,
      uri: state.uri.toString(),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.consent,
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const ProfileFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const ProfileFormScreen(isEditing: true),
      ),
      GoRoute(
        path: AppRoutes.chatPattern,
        builder: (context, state) =>
            ChatScreen(matchId: state.pathParameters['matchId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.newPost,
        builder: (context, state) => const PostComposerScreen(),
      ),
      GoRoute(
        path: AppRoutes.communitySearch,
        builder: (context, state) => CommunitySearchScreen(
          initialQuery: state.uri.queryParameters['q'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.saved,
        builder: (context, state) => const SavedPostsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.postPattern,
        builder: (context, state) =>
            PostDetailScreen(postId: state.pathParameters['postId'] ?? ''),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                PostComposerScreen(postId: state.pathParameters['postId']),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.memberPattern,
        builder: (context, state) =>
            MemberProfileScreen(uid: state.pathParameters['uid'] ?? ''),
        routes: [
          GoRoute(
            path: 'followers',
            builder: (context, state) => FollowListScreen(
              uid: state.pathParameters['uid'] ?? '',
              followers: true,
            ),
          ),
          GoRoute(
            path: 'following',
            builder: (context, state) => FollowListScreen(
              uid: state.pathParameters['uid'] ?? '',
              followers: false,
            ),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.discover,
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.community,
                builder: (context, state) => const CommunityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.matches,
                builder: (context, state) => const MatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _HomeShell extends ConsumerWidget {
  const _HomeShell({required this.shell});

  final StatefulNavigationShell shell;

  void _goBranch(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final newMatches = ref.watch(unstartedChatsCountProvider);
    final index = shell.currentIndex;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NeonNavBar(
        items: [
          NeonNavItem(
            icon: LineIconShape.flame,
            label: l10n.navDiscover,
            selected: index == 0,
            onTap: () => _goBranch(0),
          ),
          NeonNavItem(
            icon: LineIconShape.layers,
            label: l10n.navMySkills,
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          NeonNavItem(
            icon: LineIconShape.people,
            label: l10n.navCommunity,
            selected: index == 1,
            onTap: () => _goBranch(1),
          ),
          NeonNavItem(
            icon: LineIconShape.chat,
            label: l10n.navMatches,
            selected: index == 2,
            badgeCount: newMatches,
            badgeSemantics: l10n.newMatchesBadge(newMatches),
            onTap: () => _goBranch(2),
          ),
          NeonNavItem(
            icon: LineIconShape.person,
            label: l10n.navProfile,
            selected: index == 3,
            onTap: () => _goBranch(3),
          ),
        ],
      ),
    );
  }
}

class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final consent = ref.watch(consentProvider);
    final error = profile.error ?? consent.error;
    return Scaffold(
      body: error != null
          ? ErrorView(
              error: error,
              onRetry: () => ref
                ..invalidate(currentProfileProvider)
                ..invalidate(consentProvider),
            )
          : const LoadingView(),
    );
  }
}
