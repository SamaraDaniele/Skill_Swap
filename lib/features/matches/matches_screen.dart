import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/app_widgets.dart';
import '../auth/auth_repository.dart';
import '../profile/profile.dart';
import 'matches.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final uid = ref.watch(authStateProvider).value ?? '';
    final matches = ref
        .watch(matchesProvider)
        .whenData((list) => list.where((m) => !m.isClosed).toList());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMatches)),
      body: ContentWidth(
        child: switch (matches) {
          AsyncData(:final value) when value.isEmpty => MessageView(
            icon: Icons.handshake_outlined,
            title: l10n.matchesEmptyTitle,
            body: l10n.matchesEmptyBody,
          ),
          AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(indent: 88),
            itemBuilder: (context, index) =>
                _MatchTile(match: value[index], myId: uid),
          ),
          AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(matchesProvider),
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

class _MatchTile extends ConsumerWidget {
  const _MatchTile({required this.match, required this.myId});

  final Match match;
  final String myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final other = ref.watch(userProfileProvider(match.otherUserId(myId))).value;
    final name = other?.name ?? '';
    final last = match.lastMessage;
    return ListTile(
      leading: ProfileAvatar(name: name, photo: other?.photo),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        last ?? l10n.matchesNoMessages,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: last == null
          ? Icon(
              Icons.fiber_new_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(AppRoutes.chat(match.id)),
    );
  }
}
