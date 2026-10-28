import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';

Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester, {double width = 390, double scale = 1}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
  await _settle(tester);
  await tester.tap(find.bySemanticsLabel('Filtrlar'));
  await _settle(tester);
}

/// The Tozalash capsule's opacity (0.4 while there is nothing to reset).
double _resetOpacity(WidgetTester t) =>
    t.widget<Opacity>(find.ancestor(of: find.text('Tozalash'), matching: find.byType(Opacity)).first).opacity;

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('sections, Tozalash state, Yopish discards changes', (tester) async {
    await _openSheet(tester);

    for (final t in ['KATEGORIYA', 'HUDUD', 'SANA', 'Shahar / viloyat', 'Barcha tumanlar', '30 kun', '18 ta natijani koʻrsatish']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    // Floats over the tab bar: the sheet's Yopish sits above everything.
    expect(find.bySemanticsLabel('Yopish'), findsWidgets);
    expect(_resetOpacity(tester), 0.4);

    await tester.tap(find.text('Kalitlar').last);
    await tester.pump();
    expect(_resetOpacity(tester), 1);
    await _settle(tester);
    expect(find.text('2 ta natijani koʻrsatish'), findsOneWidget);

    // Tozalash resets but keeps the sheet open.
    await tester.tap(find.text('Tozalash'));
    await _settle(tester);
    expect(find.text('18 ta natijani koʻrsatish'), findsOneWidget);
    expect(_resetOpacity(tester), 0.4);

    // Yopish closes without applying.
    await tester.tap(find.text('Kalitlar').last);
    await _settle(tester);
    await tester.tap(find.bySemanticsLabel('Yopish').last);
    await _settle(tester);
    expect(find.text('KATEGORIYA'), findsNothing);
    expect(find.bySemanticsLabel('Filtrlar'), findsOneWidget); // no "faol" dot
  });

  testWidgets('city menu resets the district; no results disables the button', (tester) async {
    await _openSheet(tester);
    await tester.tap(find.text('Toshkent').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Andijon').last);
    await _settle(tester);

    expect(find.text('Andijon'), findsOneWidget);
    expect(find.text('Natija topilmadi'), findsOneWidget);
    await tester.tap(find.text('Natija topilmadi'));
    await tester.pumpAndSettle();
    expect(find.text('KATEGORIYA'), findsOneWidget, reason: 'disabled button keeps the sheet open');
  });

  testWidgets('glass menu opens under the row, right-aligned; source capsule shows open state', (tester) async {
    await _openSheet(tester);
    final row = tester.getRect(find.bySemanticsLabel('Shahar / viloyat, Toshkent'));
    await tester.tap(find.text('Toshkent').last);
    await tester.pumpAndSettle();
    // Below the row, or above it when there is no room; never on top of it.
    final first = tester.getRect(find.bySemanticsLabel('Toshkent').last);
    final second = tester.getRect(find.bySemanticsLabel('Samarqand'));
    expect(first.overlaps(row) || second.overlaps(row), isFalse);
    // Right edges line up: the row ends at the group edge, so does the menu.
    expect(tester.getRect(find.bySemanticsLabel('Samarqand')).right, closeTo(row.right, 0.5));
    expect(find.bySemanticsLabel('Shahar / viloyat, Toshkent'), findsOneWidget);
    // Tap outside closes it without a change.
    await tester.tapAt(const Offset(30, 300));
    await tester.pumpAndSettle();
    expect(find.text('Samarqand'), findsNothing);
  });

  testWidgets('press on the row, slide to an item, release picks it', (tester) async {
    await _openSheet(tester);
    final g = await tester.startGesture(tester.getCenter(find.text('Toshkent').last));
    await tester.pump(const Duration(milliseconds: 600)); // long press opens the menu
    await tester.pumpAndSettle();
    expect(find.text('Samarqand'), findsOneWidget);
    await g.moveTo(tester.getCenter(find.text('Buxoro')));
    await tester.pump();
    await g.up();
    await _settle(tester);
    expect(find.text('Samarqand'), findsNothing);
    expect(find.bySemanticsLabel('Shahar / viloyat, Buxoro'), findsOneWidget);
  });

  testWidgets('district menu: Barcha tumanlar first, then a divider, then districts', (tester) async {
    await _openSheet(tester);
    await tester.tap(find.text('Barcha tumanlar'));
    await tester.pumpAndSettle();
    final all = tester.getRect(find.bySemanticsLabel('Barcha tumanlar'));
    final first = tester.getRect(find.bySemanticsLabel('Bektemir'));
    // 4 + 0.5 + 4 divider block between the rows.
    expect(first.top - all.bottom, closeTo(8.5, 0.5));
    await tester.tap(find.text('Chilonzor'));
    await _settle(tester);
    expect(find.bySemanticsLabel('Tuman, Chilonzor'), findsOneWidget);
  });

  testWidgets('drag down dismisses', (tester) async {
    await _openSheet(tester);
    await tester.drag(find.text('Filtrlar').last, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('KATEGORIYA'), findsNothing);
  });

  testWidgets('scrim tap dismisses', (tester) async {
    await _openSheet(tester);
    // The 8dp strip beside the sheet is scrim.
    await tester.tapAt(const Offset(3, 400));
    await tester.pumpAndSettle();
    expect(find.text('KATEGORIYA'), findsNothing);
  });

  for (final (width, scale) in [(360.0, 1.0), (360.0, 1.3)]) {
    testWidgets('lays out at ${width.toInt()} wide, text ×$scale; button stays put', (tester) async {
      await _openSheet(tester, width: width, scale: scale);
      // Any RenderFlex overflow would have failed the test by now.
      final button = tester.getRect(find.text('18 ta natijani koʻrsatish'));
      expect(button.bottom, lessThan(844));
    });
  }
}
