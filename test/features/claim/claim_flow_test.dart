import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/features/claim/data/datasources/claim_remote_datasource.dart';
import 'package:topildi/features/listing/data/datasources/listing_remote_datasource.dart';

/// Lets route transitions finish, then the mock latency elapse.
Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

/// "Soʻrov yuborildi" has a spinner that never stops: pump fixed frames.
Future<void> _frames(WidgetTester t, {int seconds = 5}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Mock data sources wait on the test clock: pump until [f] completes.
Future<T> _await<T>(WidgetTester t, Future<T> f) async {
  var done = false;
  late T value;
  f.then((v) {
    value = v;
    done = true;
  });
  for (var i = 0; i < 100 && !done; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(done, isTrue, reason: 'mock call did not complete');
  return value;
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
    await _frames(tester);
    expect(find.text('Soʻrov'), findsOneWidget);
    expect(find.text('yuborildi!'), findsOneWidget);
    expect(find.text('Bolalar ryukzagi, koʻk'), findsOneWidget);
    expect(find.text('Topuvchi: Aziz T. · Mirzo Ulugʻbek'), findsOneWidget);
    expect(find.textContaining('Aziz T. javobingizni'), findsOneWidget);
    expect(find.text('Aziz T. tekshirmoqda'), findsOneWidget);
    // No promise about when the answer comes.
    expect(find.textContaining('Odatda'), findsNothing);
    expect(find.text('Lentaga qaytish'), findsOneWidget);
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
    await _frames(tester);
    expect(find.text('yuborildi!'), findsOneWidget);
    expect(find.textContaining('Egasi: '), findsOneWidget);
    expect(find.textContaining('tekshirmoqda'), findsOneWidget);
  });

  /// Sends a claim on someone else's found [listingId] and returns its id;
  /// the "Soʻrov yuborildi" screen is open. The mock data is shared by the
  /// tests, so each one uses its own listing.
  Future<String> sendClaim(WidgetTester tester, String listingId) async {
    _phone(tester);
    await tester.pumpWidget(TopildiApp(initialLocation: '/listing/$listingId/claim'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'Ichida rasm daftari bor, muqovasida mushuk');
    await tester.pump();
    await tester.tap(find.text('Soʻrov yuborish'));
    await _frames(tester);
    expect(find.text('yuborildi!'), findsOneWidget);
    final mine = await _await(tester, getIt<ClaimRemoteDataSource>().byClaimant('u_me', listingId));
    return mine.last.id;
  }

  testWidgets('The author accepts while the screen is open: "Qabul qilindi!"', (tester) async {
    final id = await sendClaim(tester, 'l3');
    final claims = getIt<ClaimRemoteDataSource>();
    final listing = await _await(tester, getIt<ListingRemoteDataSource>().fetchById('l3'));
    final claim = await _await(tester, claims.byId(id));
    await _await(tester, claims.accept(claim!, listing!));
    await _frames(tester, seconds: 1);
    expect(find.text('Qabul'), findsOneWidget);
    expect(find.text('qilindi!'), findsOneWidget);
    expect(find.text('Aziz T. tasdiqladi'), findsOneWidget);
    expect(find.text('Chatga oʻtish'), findsOneWidget);
    expect(find.text('Lentaga qaytish'), findsNothing);
  });

  testWidgets('The author rejects: attempts left and "Qayta urinish"', (tester) async {
    final id = await sendClaim(tester, 'l9');
    await _await(tester, getIt<ClaimRemoteDataSource>().reject(id));
    await _frames(tester, seconds: 1);
    expect(find.textContaining('Javob mos kelmadi. Yana'), findsOneWidget);
    expect(find.text('Javobingiz mos kelmadi'), findsOneWidget);
    await tester.tap(find.text('Qayta urinish'));
    await _settle(tester);
    expect(find.text('Buyumingizda qanday belgi bor?'), findsOneWidget);
  });

  testWidgets('✕ goes to the feed, not back to the claim form', (tester) async {
    await sendClaim(tester, 'l4');
    await tester.tap(find.bySemanticsLabel('Yopish'));
    await _settle(tester);
    expect(find.text('yuborildi!'), findsNothing);
    expect(find.text('Buyumingizda qanday belgi bor?'), findsNothing);
    expect(find.bySemanticsLabel('Eʼlon berish'), findsOneWidget);
  });

  testWidgets('Profil tab shows claims waiting for my answer', (tester) async {
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    await _settle(tester);
    expect(find.bySemanticsLabel(RegExp(r'^Profil, \d+ ta yangi$')), findsOneWidget);
  });
}
