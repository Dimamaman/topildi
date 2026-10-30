import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/features/report/data/datasources/report_mock_datasource.dart';
import 'package:topildi/features/report/data/datasources/report_remote_datasource.dart';
import 'package:topildi/features/report/domain/entities/report.dart';

/// Lets route transitions finish, then the mock latency elapse.
Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 1));
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 1));
  await t.pumpAndSettle();
}

/// The "yuborildi" art floats forever, so settling would never finish:
/// pump a fixed stretch of frames instead.
Future<void> _frames(WidgetTester t, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _openReport(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Yana'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Shikoyat qilish'));
  await _settle(tester);
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Eʼlon → Yana → Shikoyat: reason, send, then "allaqachon"', (tester) async {
    _phone(tester);
    // l3 is Aziz T.'s found listing, so the visitor menu is the one shown.
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l3')));
    await _settle(tester);

    // The visitor's bar carries "Yana", not a bare Ulashish button.
    expect(find.bySemanticsLabel('Yana'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Yana'));
    await tester.pumpAndSettle();
    expect(find.text('Ulashish'), findsOneWidget);
    expect(find.text('Muallifni bloklash'), findsOneWidget);

    await tester.tap(find.text('Shikoyat qilish'));
    await _settle(tester);

    expect(find.text('SABAB'), findsOneWidget);
    expect(find.text('Bolalar ryukzagi, koʻk'), findsWidgets);
    expect(find.text('Eʼlon · Aziz T.'), findsOneWidget);
    // Chat wording stays out of a listing's sheet.
    expect(find.text('Soxta eʼlon'), findsOneWidget);
    expect(find.text('Aldov'), findsNothing);

    // Without a reason "Yuborish" does nothing.
    await tester.tap(find.text('Yuborish'));
    await _settle(tester);
    expect(find.text('SABAB'), findsOneWidget);

    await tester.tap(find.text('Firibgarlik'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pul soʻrayapti');
    await tester.pumpAndSettle();
    expect(find.text('14 / 300'), findsOneWidget);

    await tester.tap(find.text('Yuborish'));
    await _frames(tester);

    expect(find.text('Shikoyatingiz yuborildi'), findsOneWidget);
    final sent = (getIt<ReportRemoteDataSource>() as ReportMockDataSource).sent;
    expect(sent.keys, ['listing_l3_u_me']);
    expect(sent.values.single.reason, ReportReason.scam);
    expect(sent.values.single.comment, 'Pul soʻrayapti');

    await tester.tap(find.text('Tayyor'));
    await _frames(tester);
    expect(find.text('Shikoyatingiz yuborildi'), findsNothing);

    // Second time around the sheet only says it is already with a moderator.
    await _openReport(tester);
    expect(find.text('Allaqachon yuborilgan'), findsOneWidget);
    expect(find.text('SABAB'), findsNothing);
    await tester.tap(find.text('Yopish'));
    await _settle(tester);
  });

  testWidgets('Oʻz eʼlonimda shikoyat va bloklash bandlari yoʻq', (tester) async {
    _phone(tester);
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l1')));
    await _settle(tester);

    await tester.tap(find.bySemanticsLabel('Yana'));
    await tester.pumpAndSettle();
    expect(find.text('Eʼlonni oʻchirish'), findsOneWidget);
    expect(find.text('Shikoyat qilish'), findsNothing);
    expect(find.text('Muallifni bloklash'), findsNothing);
  });
}
