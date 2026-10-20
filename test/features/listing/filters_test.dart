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

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Filters sheet narrows the feed with a live count', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    await _settle(tester);
    expect(find.text('6 ta topilgan buyum'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Filtrlar'));
    await _settle(tester);
    expect(find.text('6 ta natijani koʻrsatish'), findsOneWidget);

    await tester.tap(find.text('Kalitlar').last);
    await tester.tap(find.text('Hamyonlar').last);
    await _settle(tester);
    expect(find.text('2 ta natijani koʻrsatish'), findsOneWidget);

    await tester.tap(find.text('2 ta natijani koʻrsatish'));
    await _settle(tester);
    expect(find.text('2 ta topilgan buyum'), findsOneWidget);
    expect(find.text('Qora charm hamyon'), findsOneWidget);
    expect(find.text('Telefon, oq gʻilofda'), findsNothing);

    // Category chip resets to a single category.
    await tester.tap(find.text('Hammasi'));
    await _settle(tester);
    expect(find.text('6 ta topilgan buyum'), findsOneWidget);
  });
}
