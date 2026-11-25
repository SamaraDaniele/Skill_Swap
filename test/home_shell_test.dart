import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skill_swap/core/firebase_providers.dart';
import 'package:skill_swap/core/l10n/l10n.dart';
import 'package:skill_swap/core/router/app_router.dart';
import 'package:skill_swap/core/theme/app_theme.dart';
import 'package:skill_swap/features/auth/auth_repository.dart';
import 'package:skill_swap/features/matches/matches.dart';
import 'package:skill_swap/features/profile/profile.dart';
import 'package:skill_swap/features/profile/profile_form_screen.dart';

// Fictional test data only.
const me = UserProfile(
  id: 'me',
  name: 'Ana Teste',
  bio: '',
  teach: ['excel'],
  learn: ['english'],
);

Match match(String id, {String? lastMessage, bool closed = false}) => Match(
  id: id,
  userIds: const ['me', 'x'],
  lastMessage: lastMessage,
  lastMessageAt: null,
  isClosed: closed,
);

final sample = [
  match('new'),
  match('talking', lastMessage: 'Oi!'),
  match('closed', closed: true),
];

void main() {
  test('badge counts only active matches with no message yet', () async {
    final container = ProviderContainer(
      overrides: [matchesProvider.overrideWith((ref) => Stream.value(sample))],
    );
    addTearDown(container.dispose);
    container.listen(unstartedChatsCountProvider, (_, _) {});
    await container.read(matchesProvider.future);
    expect(container.read(unstartedChatsCountProvider), 1);
  });

  testWidgets('shell: five destinations, real badge, My Skills opens the '
      'skills form', (tester) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = FakeFirebaseFirestore();
    await ProfileRepository(db).save(me);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          authStateProvider.overrideWith((ref) => Stream.value('me')),
          currentProfileProvider.overrideWith((ref) => Stream.value(me)),
          consentProvider.overrideWith((ref) => Stream.value(true)),
          matchesProvider.overrideWith((ref) => Stream.value(sample)),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.dark(),
            locale: const Locale('pt'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in [
      'Match',
      'Minhas Skills',
      'Comunidade',
      'Conversas',
      'Perfil',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('1'), findsOneWidget, reason: 'one match not started');

    await tester.tap(find.text('Minhas Skills'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileFormScreen), findsOneWidget);
  });
}
