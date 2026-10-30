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

/// Opens the sheet from the eʼlon's "Yana" menu. [spinner] for the sheet
/// that shows the moderator's step turning — it never settles.
Future<void> _openReport(WidgetTester tester, {bool spinner = false}) async {
  await tester.tap(find.bySemanticsLabel('Yana'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Shikoyat qilish'));
  if (spinner) {
    await _frames(tester, 12);
  } else {
    await _settle(tester);
  }
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Eʼlon → Yana → Shikoyat: izoh, yuborish, keyin "allaqachon"', (tester) async {
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

    // The note is all the sheet asks for — no reason chips.
    expect(find.text('IZOH'), findsOneWidget);
    expect(find.text('SABAB'), findsNothing);
    expect(find.text('Bolalar ryukzagi, koʻk'), findsWidgets);
    expect(find.text('Eʼlon · Aziz T.'), findsOneWidget);

    // Under 10 characters "Yuborish" does nothing.
    await tester.enterText(find.byType(TextField), 'Pul');
    await tester.pumpAndSettle();
    expect(find.text('3 / 300'), findsOneWidget);
    await tester.tap(find.text('Yuborish'));
    await _settle(tester);
    expect(find.text('IZOH'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Pul soʻrayapti');
    await tester.pumpAndSettle();
    expect(find.text('14 / 300'), findsOneWidget);

    await tester.tap(find.text('Yuborish'));
    await _frames(tester);

    expect(find.text('Shikoyatingiz yuborildi'), findsOneWidget);
    final sent = (getIt<ReportRemoteDataSource>() as ReportMockDataSource).sent;
    expect(sent.keys, ['listing_l3_u_me']);
    // No reason is asked for, so Firestore's required field gets `other`.
    expect(sent.values.single.reason, ReportReason.other);
    expect(sent.values.single.comment, 'Pul soʻrayapti');

    await tester.tap(find.text('Tayyor'));
    await _frames(tester);
    expect(find.text('Shikoyatingiz yuborildi'), findsNothing);

    // Second time around the sheet shows where that shikoyat has got to.
    await _openReport(tester, spinner: true);
    expect(find.text('Shikoyatingiz allaqachon yuborilgan'), findsOneWidget);
    expect(find.text('Yuborildi'), findsOneWidget);
    expect(find.text('Moderator koʻrib chiqmoqda'), findsOneWidget);
    expect(find.text('Natija'), findsOneWidget);
    expect(find.text('IZOH'), findsNothing);
    // There is no button down there while it is open: the X closes it.
    expect(find.text('Yana shikoyat qilish'), findsNothing);

    // The moderator decides while the sheet is still on screen: the steps
    // follow, with no reopening, and the form is one tap away — a resolved
    // case must not silence them for good.
    (getIt<ReportRemoteDataSource>() as ReportMockDataSource).close(
      ReportTargetType.listing,
      'l3',
      'u_me',
    );
    await _frames(tester, 4);
    expect(find.text('Koʻrib chiqildi'), findsOneWidget);
    expect(find.text('Natija'), findsOneWidget);
    expect(find.text('Chora koʻrildi. Rahmat!'), findsOneWidget);
    expect(find.text('Moderator koʻrib chiqmoqda'), findsNothing);
    await tester.tap(find.text('Yana shikoyat qilish'));
    await tester.pumpAndSettle();
    expect(find.text('IZOH'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Yana aldamoqchi');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yuborish'));
    await _frames(tester);
    expect(find.text('Shikoyatingiz yuborildi'), findsOneWidget);
    // `sent` above is a snapshot, so read the mock again for the new note.
    final resent = (getIt<ReportRemoteDataSource>() as ReportMockDataSource).sent;
    expect(resent.keys, ['listing_l3_u_me']);
    expect(resent['listing_l3_u_me']?.comment, 'Yana aldamoqchi');

    await tester.tap(find.text('Tayyor'));
    await _frames(tester);
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
