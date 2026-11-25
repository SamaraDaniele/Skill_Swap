import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:skill_swap/core/error/failure.dart';
import 'package:skill_swap/core/firebase_providers.dart';
import 'package:skill_swap/core/l10n/l10n.dart';
import 'package:skill_swap/core/theme/app_theme.dart';
import 'package:skill_swap/features/auth/auth_repository.dart';
import 'package:skill_swap/features/auth/sign_in_screen.dart';

Widget _app(MockFirebaseAuth auth, {double textScale = 1}) => ProviderScope(
  overrides: [firebaseAuthProvider.overrideWithValue(auth)],
  child: MaterialApp(
    theme: AppTheme.dark(),
    locale: const Locale('pt'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const SignInScreen(),
  ),
);

void _phone(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('shows every element of the reference layout', (tester) async {
    _phone(tester, const Size(393, 852));
    await tester.pumpWidget(_app(MockFirebaseAuth()));

    for (final text in [
      'Bem-vindo de volta',
      'Ensine o que sabe. Aprenda o que ama.',
      'E-mail',
      'Senha',
      'Entrar',
      'Esqueci minha senha',
      'ou',
      'Continuar com Google',
      'Continuar com Apple',
      'Novo por aqui?',
      'Criar conta',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.bySemanticsLabel('Skill Swap'), findsOneWidget);
  });

  testWidgets('password starts hidden and the eye toggles it', (tester) async {
    _phone(tester, const Size(393, 852));
    await tester.pumpWidget(_app(MockFirebaseAuth()));

    EditableText passwordField() => tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Senha'),
        matching: find.byType(EditableText),
      ),
    );

    expect(passwordField().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
    // Revealed or not, the password never feeds keyboard suggestions.
    expect(passwordField().enableSuggestions, isFalse);
    expect(passwordField().enableIMEPersonalizedLearning, isFalse);
  });

  testWidgets('valid credentials sign in through Firebase Auth', (
    tester,
  ) async {
    _phone(tester, const Size(393, 852));
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'ana', email: 'ana@example.com'),
    );
    await tester.pumpWidget(_app(auth));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'ana@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      'secret1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(auth.currentUser?.uid, 'ana');
  });

  testWidgets('"Criar conta" switches to sign-up without leaving', (
    tester,
  ) async {
    _phone(tester, const Size(393, 852));
    await tester.pumpWidget(_app(MockFirebaseAuth()));

    await tester.tap(find.widgetWithText(TextButton, 'Criar conta'));
    await tester.pump();

    expect(find.text('Crie sua conta'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Criar conta'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsNothing);
    expect(find.text('Já tem conta?'), findsOneWidget);
  });

  testWidgets('switching mode keeps what was typed', (tester) async {
    _phone(tester, const Size(393, 852));
    await tester.pumpWidget(_app(MockFirebaseAuth()));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'ana@example.com',
    );

    await tester.tap(find.widgetWithText(TextButton, 'Criar conta'));
    await tester.pump();

    expect(find.text('ana@example.com'), findsOneWidget);
  });

  testWidgets('wrong credentials show a generic message', (tester) async {
    _phone(tester, const Size(393, 852));
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
        .on(auth)
        .thenThrow(FirebaseAuthException(code: 'wrong-password'));
    await tester.pumpWidget(_app(auth));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'ana@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      'nope12',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('social buttons say the option is coming soon', (tester) async {
    _phone(tester, const Size(393, 852));
    final auth = MockFirebaseAuth();
    await tester.pumpWidget(_app(auth));

    await tester.tap(find.text('Continuar com Google'));
    await tester.pump();

    expect(find.textContaining('chega em breve'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('forgot password sends a reset link for the typed email', (
    tester,
  ) async {
    _phone(tester, const Size(393, 852));
    await tester.pumpWidget(_app(MockFirebaseAuth()));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'ana@example.com',
    );

    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperar senha'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar senha'), findsNothing);
    expect(find.textContaining('o link chega em instantes'), findsOneWidget);
  });

  testWidgets('reset errors are shown inside the dialog', (tester) async {
    _phone(tester, const Size(393, 852));
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(#sendPasswordResetEmail, null))
        .on(auth)
        .thenThrow(FirebaseAuthException(code: 'too-many-requests'));
    await tester.pumpWidget(_app(auth));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'ana@example.com',
    );

    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text('ana@example.com')),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining('Muitas tentativas'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('meets tap target and label guidelines', (tester) async {
    _phone(tester, const Size(393, 852));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(MockFirebaseAuth()));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    // textContrastGuideline is not used: it samples the logo image (a
    // logotype, exempt under WCAG 1.4.3) and reports its glow as text.
    handle.dispose();
  });

  for (final (name, size, scale) in [
    ('small phone', const Size(320, 568), 1.0),
    ('text at 200%', const Size(393, 852), 2.0),
    ('small phone with text at 200%', const Size(320, 568), 2.0),
    ('keyboard open', const Size(393, 852), 1.0),
  ]) {
    testWidgets('lays out without overflow: $name', (tester) async {
      _phone(tester, size);
      if (name == 'keyboard open') {
        tester.view.viewInsets = const FakeViewPadding(bottom: 340);
      }
      await tester.pumpWidget(_app(MockFirebaseAuth(), textScale: scale));
      await tester.pump();

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Continuar com Apple'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }

  group('AuthRepository.sendPasswordReset', () {
    test('does not reveal that an email is not registered', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#sendPasswordResetEmail, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      await expectLater(
        AuthRepository(auth).sendPasswordReset('nobody@example.com'),
        completes,
      );
    });

    test('other errors still surface as failures', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#sendPasswordResetEmail, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      await expectLater(
        AuthRepository(auth).sendPasswordReset('ana@example.com'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('auth error mapping', () {
    FirebaseAuthException code(String code) =>
        FirebaseAuthException(code: code);

    test('wrong password and unknown user read the same (no enumeration)', () {
      expect(
        mapToFailure(code('wrong-password')),
        isA<InvalidCredentialsFailure>(),
      );
      expect(
        mapToFailure(code('user-not-found')),
        isA<InvalidCredentialsFailure>(),
      );
      expect(
        mapToFailure(code('invalid-credential')),
        isA<InvalidCredentialsFailure>(),
      );
    });

    test('rate limiting and bad emails get their own messages', () {
      expect(
        mapToFailure(code('too-many-requests')),
        isA<TooManyRequestsFailure>(),
      );
      expect(mapToFailure(code('invalid-email')), isA<InvalidEmailFailure>());
      expect(
        mapToFailure(code('password-does-not-meet-requirements')),
        isA<WeakPasswordFailure>(),
      );
    });
  });
}
