import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/startup/skill_swap_splash_screen.dart';
import 'core/startup/startup_state.dart';
import 'core/theme/app_theme.dart';

class SkillSwapApp extends ConsumerWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          _StartupSplash(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _StartupSplash extends ConsumerWidget {
  const _StartupSplash({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SkillSwapSplashScreen(
    ready: ref.watch(startupResolvedProvider),
    child: child,
  );
}
