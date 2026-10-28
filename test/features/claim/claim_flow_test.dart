import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';

/// Lets route transitions finish, then the mock latency elapse.
Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Owner claims someone else’s found item', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    await _settle(tester);

    await tester.scrollUntilVisible(find.text('Bolalar ryukzagi, koʻk').hitTestable(), 100, scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    await tester.tap(find.text('Bolalar ryukzagi, koʻk'));
    await _settle(tester);
    await tester.tap(find.text('Bu meniki'));
    await _settle(tester);
    expect(find.text('Buyumingizda qanday belgi bor?'), findsOneWidget);
    expect(find.text('3 ta kalit = 3 ta urinish · Javobni faqat topuvchi koʻradi'), findsOneWidget);

    // Too short is refused with a reason.
    await tester.enterText(find.byType(TextField), 'Ichida: ');
    await tester.pump();
    await tester.tap(find.text('Soʻrov yuborish'));
    await tester.pump();
    expect(find.textContaining('Javobni batafsilroq yozing'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ichida rasm daftari bor, muqovasida mushuk');
    await tester.pump();
    await tester.tap(find.text('Soʻrov yuborish'));
    await _settle(tester);
    expect(find.text('Soʻrovingiz yuborildi'), findsOneWidget);
    expect(find.textContaining('Aziz T. javobingizni'), findsOneWidget);
    expect(find.textContaining('Prototip'), findsNothing);
  });

  testWidgets('Finder answers someone else’s lost item: “Men topdim”', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const TopildiApp(initialLocation: '/listing/l6'));
    await _settle(tester);

    await tester.tap(find.text('Men topdim'));
    await _settle(tester);
    expect(find.text('BUYUM SIZDA EKANINI TASDIQLANG'), findsOneWidget);
    expect(find.text('Buyumda qanday belgi bor?'), findsOneWidget);
    expect(find.text('3 ta kalit = 3 ta urinish · Javobni faqat egasi koʻradi'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Gʻilofida kichik tirnalgan joy bor');
    await tester.pump();
    await tester.tap(find.text('Soʻrov yuborish'));
    await _settle(tester);
    expect(find.text('Soʻrovingiz yuborildi'), findsOneWidget);
    expect(find.text('Egasi tekshirmoqda'), findsOneWidget);
  });

  testWidgets('Profil tab shows claims waiting for my answer', (tester) async {
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    await _settle(tester);
    expect(find.bySemanticsLabel(RegExp(r'^Profil, \d+ ta yangi$')), findsOneWidget);
  });
}
