# Components

Shared components live in [`lib/core/widgets/app_widgets.dart`](../lib/core/widgets/app_widgets.dart) unless noted.

## PrimaryButton

| | |
|---|---|
| Responsibility | The main call to action; prevents duplicate submissions. |
| Parameters | `label` (String, required), `onPressed` (VoidCallback?, required), `isLoading` (bool, default `false`), `icon` (IconData?, default `null`). |
| States | enabled, disabled (`onPressed == null`), loading (spinner, disabled). |
| Behavior | Wraps the themed `FilledButton`; cross-fades content with `AnimatedSwitcher` (reduced-motion aware). |
| Accessibility | Keeps `label` as semantics label while the spinner is shown. Height 52. |
| Limits | Long labels ellipsize on one line. |

```dart
PrimaryButton(
  label: context.l10n.saveAction,
  isLoading: _isSaving,
  onPressed: _save,
)
```

## ProfileAvatar

| | |
|---|---|
| Responsibility | Person's photo, or initials when there is none. |
| Parameters | `name` (String, required), `photo` (`Uint8List?`, already validated by `ProfilePhoto.isAcceptable`), `size` (double, default `48`). |
| Behavior | Photo cropped to a circle and decoded at the displayed size (`cacheWidth`); without a photo, or if it fails to decode, up to two initials of the first two words. Circle with `surfaceContainerHighest` fill and outline border. |
| Accessibility | Excluded from semantics (the name is always shown next to it). |

```dart
ProfileAvatar(name: profile.name, photo: profile.photo, size: 64)
```

## SkillTag

| | |
|---|---|
| Responsibility | Read-only pill showing a skill. |
| Parameters | `label` (String, required), `highlighted` (bool, default `false`). |
| States | normal (dark pill), highlighted (lime pill + check icon). |
| Accessibility | Highlight conveyed by the icon as well as color. |

```dart
SkillTag(label: Skills.label(l10n, id), highlighted: wanted.contains(id))
```

## LoadingView

No parameters. Centered `CircularProgressIndicator`.

## MessageView

| | |
|---|---|
| Responsibility | Empty and informational states. |
| Parameters | `icon` (IconData, required), `title` (String, required), `body` (String?), `actionLabel` (String?), `onAction` (VoidCallback?). The action renders only when both are set. |
| Behavior | Centered, scrollable (works with large text). |

```dart
MessageView(
  icon: Icons.handshake_outlined,
  title: l10n.matchesEmptyTitle,
  body: l10n.matchesEmptyBody,
)
```

## ErrorView

| | |
|---|---|
| Parameters | `error` (Object, required), `onRetry` (VoidCallback, required). |
| Behavior | `MessageView` with `l10n.errorTitle`, `l10n.failureMessage(error)` and a retry button. |

```dart
ErrorView(error: error, onRetry: () => ref.invalidate(matchesProvider))
```

## showAppSnackBar

`void showAppSnackBar(BuildContext context, String message)` — hides the current SnackBar and shows a new floating one. Used for action feedback and errors.

## SwipeCard

| | |
|---|---|
| Location | `lib/features/discover/swipe_card.dart` (feature-specific) |
| Parameters | `child` (Widget), `onSwiped` (ValueChanged<bool>, `true` = liked), `likeLabel`, `passLabel` (String) — all required. |
| Behavior | Follows the finger with slight rotation; shows a fading stamp; commits past 30% width or fling > 900 px/s, else snaps back; fly-out then `onSwiped`. Give it a `ValueKey` per profile so state resets for the next card. |
| Accessibility | Gesture-only; screens must provide button alternatives (Discover does). Stamp excluded from semantics. Durations zero with reduced motion. |

```dart
SwipeCard(
  key: ValueKey(top.id),
  likeLabel: l10n.likeAction,
  passLabel: l10n.passAction,
  onSwiped: (liked) => onDecide(top, liked: liked),
  child: _ProfileCard(me: me, profile: top),
)
```

## GlassPanel / GlassChip

| | |
|---|---|
| Location | `lib/core/widgets/glass.dart` |
| GlassPanel | Black 55% surface, radius (default 20), hairline white 12% border (or `borderColor`), optional `blur` (backdrop blur 12 — use on one large panel at most; skipped with reduced motion). |
| GlassChip | Pill with a skill label; `highlighted` adds a lime border, lime text and a check icon (not color-only). |

```dart
GlassPanel(
  blur: true,
  borderColor: AppColors.lime.withValues(alpha: 0.85),
  child: Text(l10n.knowledgeMatchTitle),
)
```

## KnowledgeMatch

`lib/features/discover/knowledge_match.dart` — `KnowledgeMatch.between(me, other)` returns `null` when no skill connects, else `type` (`teach` / `learn` / `exchange`), `iCanTeach` and `iCanLearn` (catalog ids). Pure function, unit-tested.

## SwipeCard (updated)

Adds `SwipeCardState.fling(liked:)` (animated exit from buttons; returns false while a decision is in progress, preventing duplicates), `enterFromLeft`, horizontal-only drag and semantic custom actions. Reach it with a stable `GlobalKey<SwipeCardState>` per profile.

## SkillSwapSplashScreen

| | |
|---|---|
| Location | `lib/core/startup/skill_swap_splash_screen.dart` |
| Responsibility | Animated brand opening over the app while it starts. Animation only; startup state comes from outside. |
| Parameters | `ready` (bool, required — startup resolved), `child` (Widget, required — the app), `onFinished` (VoidCallback?, called once after the reveal). Static `logoAsset` = `assets/branding/logo.png`. |
| Behavior | Precaches the logo (≤ 300 ms wait), plays the intro, holds while `!ready`, then reveals. Stage progress is driven by a ticker that advances at most ~34 ms per rendered frame, so stalled startup frames slow the animation instead of skipping stages. The child keeps a fixed position in the tree (its state is never rebuilt). |
| Accessibility | Semantic label on the logo; child excluded from semantics and input until finished; honors reduced motion. |
| Limits | Not a loading indicator for later screens; plays once per widget lifetime. |

```dart
MaterialApp.router(
  routerConfig: router,
  builder: (context, child) => SkillSwapSplashScreen(
    ready: ref.watch(startupResolvedProvider),
    child: child!,
  ),
)
```

## Themed Material widgets

`FilledButton`, `OutlinedButton`, `TextButton`, `TextFormField`, `Card`, `FilterChip`, `NavigationBar`, `AlertDialog`, `SnackBar` are used directly; their look comes from `AppTheme` ([DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)). There is no custom text-field or bottom-sheet wrapper (none needed yet).

## Match screen components (2026-11-20)

| Component | File | Notes |
|---|---|---|
| `MatchCard` | `lib/features/discover/match_card.dart` | Full-bleed photo (initials fallback), legibility gradient, neon corner, gradient border painter, glow. Shows only registered data. `onDetails: null` for the card waiting under the top one. |
| `DeckBackCard` | same | Empty dark glass card for stack depth. |
| `KnowledgeBanner` | same | "Match de Conhecimento"; rendered only when `KnowledgeMatch.between` is not null. |
| `MatchActionBar` | `lib/features/discover/match_actions.dart` | Undo / skip / approve / save; custom-painted X and check; press scale; `Semantics(onTap)` so screen readers can activate them. |
| `showProfileDetailsSheet` | `lib/features/discover/profile_details_sheet.dart` | Bio, all skills (connected ones highlighted), report entry point. Returns true when "Denunciar perfil" is chosen. |
| `NeonNavBar` | `lib/core/widgets/neon_nav_bar.dart` | Bottom navigation with neon selected item and optional count badge (spoken via `badgeSemantics`). |

`SwipeCard` now takes `borderRadius`, draws no border at rest (the card has its own) and scales in from `kNextCardScale` so the next card enters smoothly.
