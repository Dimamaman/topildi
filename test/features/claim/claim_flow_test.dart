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

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Owner claims someone else’s found item', (tester) async {
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    await _settle(tester);

    await tester.scrollUntilVisible(find.text('Bolalar ryukzagi, koʻk').hitTestable(), 100, scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    await tester.tap(find.text('Bolalar ryukzagi, koʻk'));
    await _settle(tester);
    await tester.tap(find.text('Bu meniki'));
    await _settle(tester);
    expect(find.text('Nega bu savol?'), findsOneWidget);
    expect(find.text('3 ta urinishingiz bor · Javobni faqat topuvchi koʻradi'), findsOneWidget);

    await tester.tap(find.text('Soʻrov yuborish'));
    await tester.pump();
    expect(find.textContaining('Javobni batafsilroq yozing'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ichida rasm daftari bor, muqovasida mushuk');
    await tester.tap(find.text('Soʻrov yuborish'));
    await _settle(tester);
    expect(find.text('Soʻrovingiz yuborildi'), findsOneWidget);
    expect(find.textContaining('Aziz T. javobingizni'), findsOneWidget);
    expect(find.textContaining('Prototip'), findsNothing);
  });
}
