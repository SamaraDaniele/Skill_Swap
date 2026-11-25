import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/line_icons.dart';
import '../matches/matches.dart';
import '../profile/profile.dart';
import '../safety/safety_ui.dart';
import 'discover.dart';
import 'match_actions.dart';
import 'deck_back_card.dart';
import 'match_card.dart';
import 'profile_details_sheet.dart';
import 'swipe_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  UserProfile? _lastSkipped;

  String? _restoredId;

  final Map<String, GlobalKey<SwipeCardState>> _cardKeys = {};

  GlobalKey<SwipeCardState> _cardKey(UserProfile p) =>
      _cardKeys.putIfAbsent(p.id, GlobalKey<SwipeCardState>.new);

  Future<void> _decide(UserProfile target, {required bool liked}) async {
    unawaited(
      liked ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact(),
    );
    setState(() {
      _lastSkipped = liked ? null : target;
      _restoredId = null;
      _cardKeys.remove(target.id);
    });
    final controller = ref.read(discoverControllerProvider.notifier);
    final bool matched;
    try {
      matched = await controller.swipe(
        target,
        liked: liked,
        topIsBusy: () =>
            _cardKeys.values.any((k) => k.currentState?.isDeciding ?? false),
      );
    } catch (error) {
      if (!mounted) return;
      if (_lastSkipped?.id == target.id) {
        setState(() => _lastSkipped = null);
      }
      showAppSnackBar(context, context.l10n.failureMessage(error));
      return;
    }
    if (matched && mounted) await _showMatch(target);
  }

  void _press(UserProfile top, {required bool liked}) {
    _cardKey(top).currentState?.fling(liked: liked);
  }

  void _undo() {
    final target = _lastSkipped;
    if (target == null) return;
    ref.read(discoverControllerProvider.notifier).restore(target);
    setState(() {
      _lastSkipped = null;
      _restoredId = target.id;
    });
  }

  Future<void> _details(UserProfile target) async {
    final me = ref.read(currentProfileProvider).value;
    if (me == null) return;
    final report = await showProfileDetailsSheet(
      context,
      me: me,
      profile: target,
    );
    if (report && mounted) await _report(target);
  }

  void _soon(String message) => showAppSnackBar(context, message);

  Future<void> _report(UserProfile target) async {
    final me = ref.read(currentProfileProvider).value;
    if (me == null) return;
    final sent = await showReportSheet(
      context,
      me: me.id,
      otherId: target.id,
      otherName: target.name,
    );
    if (!sent || !mounted) return;
    ref.read(discoverControllerProvider.notifier).remove(target);
    setState(() {
      _cardKeys.remove(target.id);
      if (_lastSkipped?.id == target.id) _lastSkipped = null;
    });
    showAppSnackBar(context, context.l10n.reportDone);
  }

  Future<void> _showMatch(UserProfile other) async {
    final me = ref.read(currentProfileProvider).value;
    if (me == null) return;
    final l10n = context.l10n;
    final openChat = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.handshake_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(l10n.matchDialogTitle, textAlign: TextAlign.center),
        content: Text(
          l10n.matchDialogBody(other.name),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.up,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.keepExploringAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.openChatAction),
          ),
        ],
      ),
    );
    if (openChat == true && mounted) {
      await context.push(AppRoutes.chat(Match.pairId(me.id, other.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deck = ref.watch(discoverControllerProvider);
    final me = ref.watch(currentProfileProvider).value;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(onNotifications: () => _soon(l10n.notificationsSoon)),
            Expanded(
              child: switch ((deck, me)) {
                (AsyncData(:final value), final me?) when value.isNotEmpty =>
                  _Deck(
                    me: me,
                    deck: value,
                    cardKey: _cardKey,
                    restoredId: _restoredId,
                    canUndo: _lastSkipped != null,
                    onSwiped: _decide,
                    onPress: _press,
                    onUndo: _undo,
                    onDetails: _details,
                    onSave: () => _soon(l10n.saveForLaterSoon),
                  ),
                (AsyncData(), _) => MessageView(
                  icon: Icons.travel_explore_rounded,
                  title: l10n.discoverEmptyTitle,
                  body: l10n.discoverEmptyBody,
                  actionLabel: _lastSkipped != null
                      ? l10n.undoAction
                      : l10n.refreshAction,
                  onAction: _lastSkipped != null
                      ? _undo
                      : () => ref.invalidate(discoverControllerProvider),
                ),
                (AsyncError(:final error), _) => ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(discoverControllerProvider),
                ),
                _ => const LoadingView(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const word = TextStyle(
      fontSize: 27,
      height: 1,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -1,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 15, 0),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Semantics(
                    header: true,
                    label: l10n.appTitle,
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _LogoMark(),
                        const SizedBox(width: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Skill',
                                style: word.copyWith(color: AppColors.white),
                              ),
                              const TextSpan(
                                text: ' ',
                                style: TextStyle(fontSize: 14),
                              ),
                              TextSpan(
                                text: 'Swap',
                                style: word.copyWith(color: AppColors.neon),
                              ),
                            ],
                          ),
                          textScaler: TextScaler.noScaling,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _HeaderButton(
              tooltip: l10n.notificationsSoon,
              onPressed: onNotifications,
              child: const LineIcon(LineIconShape.bell, size: 30),
            ),
            const SizedBox(width: 8),
            _HeaderButton(
              tooltip: l10n.openProfile,
              filled: true,
              onPressed: () => context.go(AppRoutes.profile),
              child: const LineIcon(LineIconShape.person, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  static const double _width = 54;

  static const double _height = _width * 730 / 841;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: ResizeImage(
        const AssetImage(AppAssets.logoMark),
        width: (_width * MediaQuery.devicePixelRatioOf(context)).round(),
      ),
      width: _width,
      height: _height,
      fit: BoxFit.contain,
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.filled = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: tooltip,
        onTap: onPressed,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          radius: 26,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: filled
                  ? DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.discTop, AppColors.discBottom],
                        ),
                      ),
                      child: SizedBox.square(
                        dimension: 42,
                        child: Center(child: child),
                      ),
                    )
                  : child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Deck extends StatelessWidget {
  const _Deck({
    required this.me,
    required this.deck,
    required this.cardKey,
    required this.restoredId,
    required this.canUndo,
    required this.onSwiped,
    required this.onPress,
    required this.onUndo,
    required this.onDetails,
    required this.onSave,
  });

  final UserProfile me;
  final List<UserProfile> deck;
  final GlobalKey<SwipeCardState> Function(UserProfile) cardKey;
  final String? restoredId;
  final bool canUndo;
  final Future<void> Function(UserProfile, {required bool liked}) onSwiped;
  final void Function(UserProfile, {required bool liked}) onPress;
  final VoidCallback onUndo;
  final ValueChanged<UserProfile> onDetails;
  final VoidCallback onSave;

  static const double maxWidth = 440;

  static const double minHeight = 500;
  static const double compactCardHeight = 420;

  static Widget _pose(Offset offset, double angle, Widget child) =>
      Positioned.fill(
        child: Transform.translate(
          offset: offset,
          child: Transform.rotate(angle: angle, child: child),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = deck.first;
    final stack = Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (deck.length > 1) ...[
            _pose(
              const Offset(8, -12),
              0.012,
              const RepaintBoundary(child: DeckBackCard()),
            ),
            _pose(
              const Offset(-10, 2),
              -0.008,
              const RepaintBoundary(child: DeckBackCard()),
            ),
            _pose(
              Offset.zero,
              kDeckTilt,
              Transform.scale(
                scale: kNextCardScale,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: RepaintBoundary(
                      child: MatchCard(
                        key: ValueKey('next-${deck[1].id}'),
                        me: me,
                        profile: deck[1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          _pose(
            Offset.zero,
            kDeckTilt,
            SwipeCard(
              key: cardKey(top),
              likeLabel: l10n.likeAction,
              passLabel: l10n.passAction,
              semanticsLabel: l10n.profileCardLabel(top.name),
              borderRadius: kDeckCardRadius,
              enterFromLeft: top.id == restoredId,
              onSwiped: (liked) => onSwiped(top, liked: liked),
              child: MatchCard(
                me: me,
                profile: top,
                labelled: false,
                onDetails: () => onDetails(top),
              ),
            ),
          ),
        ],
      ),
    );
    final actions = MatchActionBar(
      onUndo: canUndo ? onUndo : null,
      onPass: () => onPress(top, liked: false),
      onLike: () => onPress(top, liked: true),
      onSave: onSave,
    );
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: constraints.maxHeight < minHeight
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: compactCardHeight, child: stack),
                      const SizedBox(height: 12),
                      actions,
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(child: stack),
                    const SizedBox(height: 12),
                    actions,
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }
}
