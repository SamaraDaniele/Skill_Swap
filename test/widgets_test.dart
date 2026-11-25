import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skill_swap/core/firebase_providers.dart';
import 'package:skill_swap/core/l10n/l10n.dart';
import 'package:skill_swap/core/theme/app_theme.dart';
import 'package:skill_swap/features/auth/auth_repository.dart';
import 'package:skill_swap/features/auth/sign_in_screen.dart';
import 'package:skill_swap/features/profile/profile.dart';
import 'package:skill_swap/features/profile/profile_form_screen.dart';

Widget harness(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('pt'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('sign in validates fields in Portuguese', (tester) async {
    await tester.pumpWidget(
      harness(
        const SignInScreen(),
        overrides: [firebaseAuthProvider.overrideWithValue(MockFirebaseAuth())],
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail válido'), findsOneWidget);
    expect(find.text('Use pelo menos 6 caracteres'), findsOneWidget);
  });

  testWidgets('[H1] profile setup cannot be saved without consent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = FakeFirebaseFirestore();

    await tester.pumpWidget(
      harness(
        // In the app the router keeps the auth state alive; do the same here.
        Consumer(
          builder: (context, ref, _) {
            ref.watch(authStateProvider);
            return const ProfileFormScreen();
          },
        ),
        overrides: [
          firestoreProvider.overrideWithValue(db),
          authStateProvider.overrideWith((ref) => Stream.value('nova')),
          currentProfileProvider.overrideWith((ref) => Stream.value(null)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Nova');
    await tester.tap(find.text('Excel').first);
    await tester.tap(find.text('Inglês').last);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('É preciso aceitar para continuar'), findsOneWidget);
    expect((await db.doc('users/nova').get()).exists, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect((await db.doc('users/nova').get()).exists, isTrue);
    expect((await db.doc('users/nova/private/consent').get()).exists, isTrue);
  });
}
