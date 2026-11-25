# Match screen v2 (neon mockup) — review findings (2026-11-20)

**Update (same day): all findings below were fixed.** Validation: `dart format` clean, `flutter analyze` no issues, `flutter test` 117 passed (new: tablet/desktop width, landscape, reduced motion, single semantics node with swipe actions, failed like during the next decision, badge provider, shell + My Skills). Device: card with real data, ⓘ sheet, check-button glow (was clipped to a square) verified on the Pixel 8 emulator. Offline render harness removed.

Original notes:

State when paused: `dart format` clean, `flutter analyze` no issues, `flutter test` 111 passed.
Device: header, empty state, nav bar and line icons checked on the emulator; cards with real
photos NOT yet checked on device (account "Lucas" had swiped everyone; user was signing in
with another test account).

Temporary: `test/visual/match_render_test.dart` (offline render harness for comparing with the
mockup; delete before finishing). Run with
`--dart-define=RENDER_OUT=<dir> --dart-define=RENDER_PHOTO=<jpg>`.

## Code review findings still to fix

| Sev | Finding | Fix |
|---|---|---|
| High | Deck has no max width (tablet/desktop huge card, swipe threshold 30 % of width) and collapses in landscape | `Center` + `ConstrainedBox(maxWidth: 440)`; when height < ~520 make the deck scrollable with a fixed card height; tests at 1280×800 and 915×412 |
| Med | Custom buttons announce label twice (Tooltip + Semantics) | `Tooltip(excludeFromSemantics: true)` in `_RoundAction` and `_HeaderButton` |
| Med | Failed like restores the card on top and can unmount the next card mid-decision (decision lost); catch clears `_lastSkipped` of another card | Restore at index 1 when the top card is deciding; clear `_lastSkipped` only if same id; regression test with a delayed failing fake repository |
| Med | Repaint cost while dragging | `RepaintBoundary` around `SwipeCard` child and around back cards + next card |
| Med | Swipe custom semantic actions may be on a separate unlabeled node | One container node: label in `SwipeCard`, `MatchCard` not a container there; test custom actions on "Perfil de …" |
| Med | 320 dp / 200 % text: panels truncate, tag overlaps details (fixed `top: 84`), reverse scroll hides name | Stack panels when text scale > 1.3, hide tag then, no reverse scroll |
| Med | Missing tests: shell badge rule, Minhas Skills push, reduced motion, next card excluded from semantics | Add `newMatchesCountProvider` (+ `select`) and tests |
| Low | Badge string says "novos" but counts matches without messages | "{count} sem conversa ainda" |
| Low | `kNextCardScale` sits under `SwipeCard` doc comment; controller created lazily; one-frame flash on `enterFromLeft`; approval shown by color only (add like stamp); `_showMatch` inside try; `me!`; `_cardKeys` not cleaned on report | Small fixes in `swipe_card.dart` / `discover_screen.dart` |
| Low | Colors outside tokens; 3 public widgets in `match_card.dart`; logo crop via magic numbers; "Afinidade" vs "compatível" naming | Move to `AppColors`; split files; pre-cropped `logo_mark.png`; unify naming |

Known limitations (not bugs): no age/city/verified/level/favorites/notification data in the
backend (shown honestly or "em breve"); photos are 384 px (blurry when full-bleed); Roboto
instead of the mockup font; brand name kept as Skill Swap.
