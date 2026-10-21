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

  testWidgets('Finder: claims → accept → chat → returned → success', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    await _settle(tester);

    await tester.tap(find.text('Qora charm hamyon'));
    await _settle(tester);
    expect(find.text('Mening eʼlonim'), findsOneWidget);
    expect(find.text('2 ta yangi soʻrov'), findsOneWidget);
    expect(find.text('Ikki kishi bu buyum ularniki ekanini aytmoqda.'), findsOneWidget);
    await tester.tap(find.text('Soʻrovlarni koʻrish · 2'));
    await _settle(tester);

    expect(find.text('Soʻrovlar · 2'), findsOneWidget);
    expect(find.text('Siz yozgan yashirin belgi'), findsOneWidget);
    expect(find.text('Ichida koʻk rangli bank kartasi va 2 ta suratli chipta bor'), findsOneWidget);

    // Reject Anvar after confirming.
    await tester.ensureVisible(find.text('Rad etish').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rad etish').last);
    await tester.pumpAndSettle();
    expect(find.text('Soʻrovni rad etasizmi?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Rad etish').last);
    await _settle(tester);
    expect(find.text('Rad etildi'), findsOneWidget);

    // Accept Malika → chat opens.
    await tester.ensureVisible(find.text('Qabul qilish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qabul qilish'));
    await _settle(tester);
    expect(find.text('Egaligi tasdiqlangan'), findsOneWidget);
    expect(find.text('Javob yashirin belgiga mos keldi. Chat ochildi.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Soat 18:00 da metro yonida');
    await tester.tap(find.byTooltip('Yuborish'));
    await _settle(tester);
    expect(find.text('Soat 18:00 da metro yonida'), findsOneWidget);

    await tester.tap(find.text('Qaytarildi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ha, qaytarildi'));
    await _settle(tester);

    expect(find.text('Buyum egasiga qaytdi!'), findsOneWidget);
    expect(find.text('Mehribon qoʻshni'), findsOneWidget);
    expect(find.text('Siz 5 ta buyumni egasiga qaytardingiz'), findsOneWidget);
    expect(find.text('Malika K. yozdi'), findsOneWidget);

    await tester.ensureVisible(find.text('Lentaga qaytish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lentaga qaytish'));
    await _settle(tester);
    // Back on the feed, and the returned listing has left it.
    expect(find.text('Kalitlar toʻplami, 3 dona'), findsOneWidget);
    expect(find.text('Qora charm hamyon'), findsNothing);
  });
}
