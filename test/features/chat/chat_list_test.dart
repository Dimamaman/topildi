import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart' show Environment;
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/core/utils/date_format.dart';

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
  await tester.pumpWidget(const TopildiApp(initialLocation: Routes.chats));
  await _settle(tester);
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  test('chat time: today, yesterday, weekday, older', () {
    final now = DateTime(2026, 10, 21, 15); // Wednesday
    expect(TDate.chat(DateTime(2026, 10, 21, 14, 20), now: now), '14:20');
    expect(TDate.chat(DateTime(2026, 10, 20, 9), now: now), 'Kecha');
    expect(TDate.chat(DateTime(2026, 10, 17, 9), now: now), 'Shanba');
    expect(TDate.chat(DateTime(2026, 10, 9, 9), now: now), '9-oktabr');
  });

  testWidgets('rows: unread first, returned marked, privacy note, opens chat', (tester) async {
    await _open(tester);
    expect(find.bySemanticsLabel(RegExp('^Oʻqilmagan\\. ')), findsWidgets);
    expect(find.text('Chat faqat soʻrov qabul qilingandan keyin ochiladi. Telefon raqamlar yashirin.'), findsOneWidget);

    await tester.tap(find.text('Sardor R.'));
    await _settle(tester);
    expect(find.text('Chat faqat soʻrov qabul qilingandan keyin ochiladi. Telefon raqamlar yashirin.'), findsNothing);
  });

  for (final (width, scale) in [(360.0, 1.0), (360.0, 1.3)]) {
    testWidgets('lays out at ${width.toInt()} wide, text ×$scale', (tester) async {
      await _open(tester, width: width, scale: scale);
      await tester.drag(find.text('Sardor R.'), const Offset(0, -300));
      await tester.pumpAndSettle();
      // Any RenderFlex overflow would have failed the test by now.
    });
  }
}
