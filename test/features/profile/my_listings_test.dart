import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/core/widgets/feed_card.dart';

Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

/// Width of the floating "Eʼlon berish" button.
double _fabWidth(WidgetTester t) => t.getSize(find.bySemanticsLabel('Eʼlon berish')).width;

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Mening eʼlonlarim: tags, tabs, collapsing title and shrinking add button', (tester) async {
    // Short screen so two cards are enough to scroll.
    tester.view.physicalSize = const Size(390 * 3, 600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.myListings));
    await _settle(tester);

    expect(find.text('Faol · 5'), findsOneWidget);
    expect(find.text('Qaytarilgan · 4'), findsOneWidget);
    // Status tag first, then the type tag with dot + text.
    // l1 and l_mine3 both have two pending claims, l_mine2 has one.
    expect(find.text('Soʻrov bor · 2'), findsNWidgets(2));
    expect(find.text('Soʻrov bor · 1'), findsOneWidget);
    expect(find.text('Faol'), findsNWidgets(2));
    expect(find.text('Topilgan'), findsNWidgets(3));
    expect(find.text('Yoʻqolgan'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Orqaga'), findsOneWidget);

    final wide = _fabWidth(tester);
    expect(find.text('Eʼlon berish'), findsOneWidget);

    // Scrolling down collapses the title and shrinks the button to a 56dp circle.
    await tester.drag(find.text('Qora charm hamyon'), const Offset(0, -150));
    await tester.pumpAndSettle();
    final inline = find.ancestor(of: find.text('Mening eʼlonlarim'), matching: find.byType(Opacity));
    expect(tester.widget<Opacity>(inline.first).opacity, 1);
    expect(_fabWidth(tester), 56);
    // Scrolling back up brings it back.
    await tester.drag(find.text('Qora charm hamyon'), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(_fabWidth(tester), wide);

    // Qaytarilgan tab: like Lenta, the list reloads behind skeleton cards
    // while the tabs keep their counts; then cards carry "Qaytarildi".
    await tester.tap(find.text('Qaytarilgan · 4'));
    await tester.pump();
    expect(find.byType(FeedCardSkeleton), findsNWidgets(2));
    expect(find.text('Faol · 5'), findsOneWidget);
    await _settle(tester);
    expect(find.text('Qaytarildi'), findsNWidgets(4));
    expect(find.text('Soʻrov bor · 2'), findsNothing);

    // Swiping the list right goes back to Faol.
    await tester.fling(find.text('Qaytarildi').first, const Offset(300, 0), 1000);
    await _settle(tester);
    expect(find.text('Soʻrov bor · 2'), findsNWidgets(2));

    // Card opens the listing.
    await tester.tap(find.text('Qora charm hamyon'));
    await _settle(tester);
    expect(find.text('Faol · 5'), findsNothing);
  });

  for (final (width, scale) in [(360.0, 1.0), (360.0, 1.3)]) {
    testWidgets('lays out at ${width.toInt()} wide, text ×$scale', (tester) async {
      tester.view.physicalSize = Size(width * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(const TopildiApp(initialLocation: Routes.myListings));
      await _settle(tester);
      await tester.tap(find.textContaining('Qaytarilgan · '));
      await _settle(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
