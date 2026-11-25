import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skill_swap/core/theme/app_theme.dart';
import 'package:skill_swap/core/widgets/line_icons.dart';
import 'package:skill_swap/core/widgets/neon_nav_bar.dart';

void main() {
  Future<List<String>> pumpBar(
    WidgetTester tester, {
    int badge = 0,
    double textScale = 1,
    Size size = const Size(393, 852),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final taps = <String>[];
    NeonNavItem item(String label, {bool selected = false, int count = 0}) =>
        NeonNavItem(
          icon: LineIconShape.star,
          label: label,
          selected: selected,
          badgeCount: count,
          badgeSemantics: '$count novos',
          onTap: () => taps.add(label),
        );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            bottomNavigationBar: NeonNavBar(
              items: [
                item('Match', selected: true),
                item('Minhas Skills'),
                item('Comunidade'),
                item('Conversas', count: badge),
                item('Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('shows the five destinations and reports taps', (tester) async {
    final taps = await pumpBar(tester);
    for (final label in [
      'Match',
      'Minhas Skills',
      'Comunidade',
      'Conversas',
      'Perfil',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Conversas'));
    await tester.tap(find.text('Minhas Skills'));
    await tester.tap(find.text('Comunidade'));
    expect(taps, ['Conversas', 'Minhas Skills', 'Comunidade']);
  });

  testWidgets('badge only when there is something to count', (tester) async {
    await pumpBar(tester);
    expect(find.text('0'), findsNothing);

    final handle = tester.ensureSemantics();
    await pumpBar(tester, badge: 3);
    expect(find.text('3'), findsOneWidget);
    expect(find.bySemanticsLabel('Conversas, 3 novos'), findsOneWidget);
    handle.dispose();

    await pumpBar(tester, badge: 12);
    expect(find.text('9+'), findsOneWidget);
  });

  testWidgets('selected state is exposed to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBar(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Match')),
      matchesSemantics(
        label: 'Match',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('320 dp at 200 % text does not overflow', (tester) async {
    await pumpBar(tester, badge: 3, textScale: 2, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    // Five items of 64 dp each still keep 48 dp touch targets.
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
