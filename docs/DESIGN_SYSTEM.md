# Design System

Source of truth: [`lib/core/theme/app_tokens.dart`](../lib/core/theme/app_tokens.dart) and [`lib/core/theme/app_theme.dart`](../lib/core/theme/app_theme.dart). Never hard-code colors, spacing or radii in widgets; read them from `Theme.of(context)` or the token classes.

## Brand palette

| Token | Hex | Role |
|---|---|---|
| `AppColors.black` | `#000000` | Dominant color: scaffold, app bar, navigation bar backgrounds. |
| `AppColors.white` | `#FFFFFF` | Primary text and icons on dark surfaces. |
| `AppColors.lime` | `#CBF615` | Brand accent: primary buttons, selected nav indicator, selected chips, own chat bubbles, highlighted tags, focus borders, progress indicators, compatibility badge. |

Approximate target: ~75% black/dark surfaces, ~20% white/neutral, ~5% lime. Lime marks *the* important action on a screen; don't use it decoratively.

## Neutrals and semantic colors (dark theme)

| Token | Hex | Used for (`ColorScheme` slot) |
|---|---|---|
| `surface1` | `#0E0E0E` | `surfaceContainer` — cards |
| `surface2` | `#161616` | `surfaceContainerHigh` — fields, dialogs, sheets, other person's bubbles |
| `surface3` | `#202020` | `surfaceContainerHighest` — avatars, tags, disabled buttons |
| `outline` | `#3A3A3A` | `outline` — outlined buttons, avatar border |
| `outlineSoft` | `#262626` | `outlineVariant` — card border, dividers |
| `textSecondary` | `#A6A6A6` | `onSurfaceVariant` — secondary text, inactive icons |
| `error` | `#FF6B6B` | `error` — validation and error text only |

## Light theme

`AppTheme.light()` exists for future use but the app runs with `ThemeMode.dark`. In light mode lime fails contrast on white, so **black** is `primary` and lime is only `primaryContainer` (always with black content).

## Text colors

- Primary: `onSurface` (white).
- Secondary: `onSurfaceVariant` (#A6A6A6, ≈ 8.6:1 on black).
- On lime: always black (`onPrimary` / `onPrimaryContainer`).

## Interactive states

- Buttons disabled: `surfaceContainerHighest` background + `onSurfaceVariant` text.
- Focus (fields): 1.5 px lime border. Error: red border.
- Pressed: Material ink sparkle.
- Selected: lime fill + black content (+ checkmark on chips/tags).

## Typography

System font (Roboto on Android, SF on iOS) — no bundled fonts, smaller app. Material 3 type scale with adjustments:

| Style | Adjustment | Use |
|---|---|---|
| `headlineMedium` | w700, letter-spacing −0.5 | Screen titles, card name |
| `headlineSmall` | w700, −0.3 | Profile name, dialog title |
| `titleLarge` | w600 | App bar titles, empty-state titles |
| `titleMedium` | w600 | Section headers |
| `labelLarge` | w600, +0.2 | Buttons, chips |
| `bodyLarge/Medium` | line height 1.45 | Body text |

All sizes scale with the system text scale.

## Spacing (`AppSpacing`, multiples of 4)

`xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · xxxl 32 · huge 40 · giant 48`. Screen padding is usually `xxl` (24); gaps between sibling controls `sm`–`md`.

## Radii (`AppRadius`)

`sm 10` (brand mark, stamps) · `md 14` (buttons, fields, snackbars) · `lg 20` (chat bubbles) · `xl 28` (cards, dialogs, sheets, chat composer) · `pill 999` (tags, badges).

## Icons

Material Symbols, *rounded* variant; outlined for inactive nav, filled for active. Size 20–24 in controls.

## Components (themed)

| Component | Spec |
|---|---|
| `FilledButton` | Lime background, black label, min 64×52, radius 14. |
| `OutlinedButton` | White label, `outline` border, min 64×52. |
| `TextButton` | White label, min 48×48. |
| `TextField` | Filled `surface2`, no border at rest, lime focus border, 16 px padding. |
| `Card` | `surface1`, 1 px `outlineSoft` border, radius 28, no elevation. |
| `NavigationBar` | Black, height 68, lime pill indicator, black selected icon. |
| `Chip` | `surface2` / lime when selected, stadium shape. |
| `Dialog` / `BottomSheet` | `surface2`, radius 28, no tint. |
| `SnackBar` | Floating, white background with black text (inverse), radius 14. |

No shadows, no gradients anywhere.

## Motion (`AppMotion`)

`short 150 ms` (switches), `medium 250 ms` (card snap/fly-out), curve `easeOutCubic`. Always obtain durations through `AppMotion.of(context, …)`, which returns zero when the OS requests reduced motion. Android pages use `FadeForwardsPageTransitionsBuilder`; iOS keeps the native Cupertino transition.

## Brand logo and opening

- Asset: `assets/branding/logo.png` (1536×1024, transparent background, glow included). Never recolor, redraw or crop it; scale proportionally only.
- Used by the opening animation (`SkillSwapSplashScreen`). Native launch screens are plain black on purpose (no logo), so the Flutter animation is the first visible brand moment.
- The splash glow is a single radial gradient (lime 28% → 0%) — the only gradient allowed in the app, because it reproduces the logo's neon light.

## Loading, empty and error states

- Loading: centered `CircularProgressIndicator` (lime) via `LoadingView`; buttons show inline spinners.
- Empty: `MessageView` — lime icon in a dark circle, title, body, optional outlined action.
- Error: `ErrorView` — same layout, human message from `failureMessage`, "Tentar novamente".

## Responsiveness

Phones first (≥ 320 dp); every route is checked from 320×568 to 1024×1366, in phone landscape and with system text up to 200 % (`test/responsive_matrix_test.dart`).
- Screen content is capped by `ContentWidth` (720 dp, centered) on tablets and wide windows; the Match deck caps at 440 dp; the auth form at 420.
- Action menus use `showActionSheet` (scrolls when the list does not fit). Paired buttons use `AdaptiveButtonRow` (stack instead of breaking words).
- Never break words or clip text to fit: wrap, stack, or (for single-word labels like the bottom bar) shrink all labels alike, never below the default size.
- Decorative text (initials, wordmark) uses `TextScaler.noScaling`; real text always scales.

## Accessibility and contrast

| Pair | Ratio (approx.) |
|---|---|
| White on black | 21:1 |
| Black on lime `#CBF615` | ≈ 17:1 |
| Lime on black | ≈ 17:1 |
| `#A6A6A6` on black | ≈ 8.6:1 |
| White on `#161616` | ≈ 18:1 |

Ratios computed from WCAG relative luminance, not measured on devices. Meaning never relies only on color (checkmarks on selected chips/tags). Touch targets ≥ 48 dp.

## Rules for new features

1. Add a token before using a new value; don't introduce new hues (semantic success/warning only if a state truly needs it).
2. At most one lime-filled control per screen region.
3. Use `PrimaryButton`, `MessageView`, `ErrorView`, `LoadingView`, `SkillTag`, `ProfileAvatar` before writing new ones.
4. Every screen must have loading, empty and error states.
5. Every icon-only button needs a `tooltip`.
