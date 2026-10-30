import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/features/block/domain/repositories/block_repository.dart';
import 'package:topildi/features/listing/domain/entities/listing.dart';
import 'package:topildi/features/listing/domain/repositories/listing_repository.dart';

Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 1));
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 1));
  await t.pumpAndSettle();
}

/// The empty-state art floats forever, so settling would never finish.
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

Future<List<String>> _feedAuthors(WidgetTester tester) async {
  final result = await tester.runAsync(
    () => getIt<ListingRepository>().getListings(const ListingQuery(type: ListingType.found)),
  );
  return result!.getOrElse((_) => const ListingPage(items: [], total: 0)).items.map((l) => l.author.id).toList();
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  tearDown(() async {
    for (final uid in ['u_aziz', 'u_sardor']) {
      await getIt<BlockRepository>().unblock(uid);
    }
  });

  testWidgets('Eʼlon → Muallifni bloklash: Lentaga qaytadi, eʼlonlari yoʻqoladi', (tester) async {
    _phone(tester);
    expect(await _feedAuthors(tester), contains('u_aziz'));

    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l3')));
    await _settle(tester);

    await tester.tap(find.bySemanticsLabel('Yana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muallifni bloklash'));
    await _settle(tester);

    expect(find.text('Aziz T.ni bloklaysizmi?'), findsOneWidget);
    expect(find.text('Uning eʼlonlari sizga koʻrinmaydi'), findsOneWidget);

    await tester.tap(find.text('Bloklash').last);
    await _frames(tester, 12);

    // The sheet and the eʼlon are both gone: the Lenta is underneath.
    expect(find.text('Aziz T.ni bloklaysizmi?'), findsNothing);
    expect(find.text('Eʼlon'), findsNothing);
    expect(await _feedAuthors(tester), isNot(contains('u_aziz')));
  });

  testWidgets('Profil → Bloklanganlar: roʻyxat, blokdan chiqarish, boʻsh holat', (tester) async {
    _phone(tester);
    await tester.runAsync(() => getIt<BlockRepository>().block('u_sardor', 'Sardor R.'));

    await tester.pumpWidget(TopildiApp(initialLocation: Routes.blocked));
    await _settle(tester);

    expect(find.text('Bloklanganlar'), findsWidgets);
    expect(find.text('Sardor R.'), findsOneWidget);
    expect(
      find.text('Bloklangan odamlar sizga yoza olmaydi va soʻrov yubora olmaydi. Ularning eʼlonlari sizga koʻrinmaydi.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Blokdan chiqarish'));
    await _frames(tester, 12);

    expect(find.text('Sardor R.'), findsNothing);
    expect(find.text('Hech kim bloklanmagan'), findsOneWidget);
  });

  testWidgets('Chat → Bloklash: yozish paneli oʻrnida banner, keyin qaytadi', (tester) async {
    _phone(tester);
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.chat('c_sardor')));
    await _settle(tester);

    expect(find.text('Xabar yozing…'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Koʻproq'));
    await tester.pumpAndSettle();
    expect(find.text('Eʼlonni koʻrish'), findsOneWidget);
    await tester.tap(find.text('Bloklash'));
    await _settle(tester);
    expect(find.text('Sardor R.ni bloklaysizmi?'), findsOneWidget);

    await tester.tap(find.text('Bloklash').last);
    await _frames(tester, 12);

    // The banner's own sentence is rich text; the way back is the plain one.
    expect(find.textContaining('Siz bloklagansiz.'), findsOneWidget);
    expect(find.text('Blokdan chiqarish'), findsOneWidget);
    expect(find.text('Xabar yozing…'), findsNothing);

    await tester.tap(find.text('Blokdan chiqarish'));
    await _frames(tester, 12);
    expect(find.textContaining('Siz bloklagansiz.'), findsNothing);
    expect(find.text('Xabar yozing…'), findsOneWidget);
  });
}
