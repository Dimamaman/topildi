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

Future<void> _open(WidgetTester tester, {double width = 390, double scale = 1}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(const TopildiApp(initialLocation: Routes.notifications));
  await _settle(tester);
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('groups, unread rows, Hammasi oʻqildi', (tester) async {
    await _open(tester);
    expect(find.text('BUGUN'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Oʻqilmagan\\. ')), findsWidgets);
    expect(find.bySemanticsLabel('Orqaga'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Hammasi oʻqildi'));
    await _settle(tester);
    expect(find.bySemanticsLabel(RegExp('^Oʻqilmagan\\. ')), findsNothing);
    // Nothing left to read: the capsule hides.
    expect(find.bySemanticsLabel('Hammasi oʻqildi').hitTestable(), findsNothing);
  });

  testWidgets('tapping an accepted claim opens the chat', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Sardor R. soʻrovingizni qabul qildi. Chatda kelishib oling.'));
    await _settle(tester);
    expect(find.text('BUGUN'), findsNothing);
  });

  for (final (width, scale) in [(360.0, 1.0), (360.0, 1.3)]) {
    testWidgets('lays out at ${width.toInt()} wide, text ×$scale', (tester) async {
      await _open(tester, width: width, scale: scale);
      await tester.drag(find.text('BUGUN'), const Offset(0, -400));
      await tester.pumpAndSettle();
      // Any RenderFlex overflow would have failed the test by now.
    });
  }
}
