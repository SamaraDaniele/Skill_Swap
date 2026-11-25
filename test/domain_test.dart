import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_swap/core/router/app_router.dart';
import 'package:skill_swap/core/router/app_routes.dart';
import 'package:skill_swap/features/matches/matches.dart';
import 'package:skill_swap/features/profile/profile.dart';

UserProfile profile(
  String id, {
  List<String> teach = const [],
  List<String> learn = const [],
}) => UserProfile(id: id, name: id, bio: '', teach: teach, learn: learn);

void main() {
  group('Compatibility.score', () {
    test('is 100 for a perfect mutual exchange', () {
      final me = profile('a', teach: ['excel'], learn: ['english']);
      final other = profile('b', teach: ['english'], learn: ['excel']);
      expect(Compatibility.score(me, other), 100);
    });

    test('is 50 when only one side benefits', () {
      final me = profile('a', teach: ['excel'], learn: ['english']);
      final other = profile('b', teach: ['english'], learn: ['guitar']);
      expect(Compatibility.score(me, other), 50);
    });

    test('is 0 with no overlap or empty wishes', () {
      expect(Compatibility.score(profile('a'), profile('b')), 0);
    });
  });

  test('Match.pairId is order independent', () {
    expect(Match.pairId('b', 'a'), Match.pairId('a', 'b'));
    expect(Match.pairId('a', 'b'), 'a_b');
  });

  group('resolveRedirect', () {
    final me = profile('me');

    String? go({
      AsyncValue<String?> auth = const AsyncData('me'),
      AsyncValue<UserProfile?>? profileState,
      AsyncValue<bool> consent = const AsyncData(true),
      String location = AppRoutes.discover,
    }) => resolveRedirect(
      auth: auth,
      profile: profileState ?? AsyncData(me),
      consent: consent,
      location: location,
    );

    test('waits on splash while auth loads', () {
      expect(
        go(auth: const AsyncLoading(), profileState: const AsyncLoading()),
        AppRoutes.splash,
      );
    });

    test('sends signed-out users to sign in', () {
      expect(
        go(auth: const AsyncData(null), profileState: const AsyncData(null)),
        AppRoutes.signIn,
      );
    });

    test('sends users without profile to setup', () {
      expect(
        go(profileState: const AsyncData(null), location: AppRoutes.splash),
        AppRoutes.setup,
      );
    });

    test('[H1] users without consent must accept it before anything else', () {
      expect(go(consent: const AsyncData(false)), AppRoutes.consent);
      expect(
        go(consent: const AsyncData(false), location: AppRoutes.matches),
        AppRoutes.consent,
      );
      expect(
        go(consent: const AsyncData(false), location: AppRoutes.consent),
        isNull,
      );
    });

    test('[H1] waits on splash while consent loads', () {
      expect(go(consent: const AsyncLoading()), AppRoutes.splash);
    });

    test('the terms can be read in any state', () {
      expect(
        go(auth: const AsyncData(null), location: AppRoutes.terms),
        isNull,
      );
      expect(
        go(consent: const AsyncData(false), location: AppRoutes.terms),
        isNull,
      );
    });

    test('moves ready users from entry routes to discover', () {
      expect(go(location: AppRoutes.setup), AppRoutes.discover);
      expect(go(location: AppRoutes.consent), AppRoutes.discover);
      expect(go(location: AppRoutes.matches), isNull);
    });
  });
}
