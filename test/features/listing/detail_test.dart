import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/core/error/failure.dart';
import 'package:topildi/features/claim/domain/entities/claim.dart';
import 'package:topildi/features/claim/domain/repositories/claim_repository.dart';
import 'package:topildi/features/listing/domain/repositories/listing_repository.dart';

/// Lets route transitions finish, then the mock latency elapse (listing, then claims).
Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 1));
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 1));
  await t.pumpAndSettle();
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Visitor: Bu meniki, then Soʻrov yuborildi once a claim is pending', (tester) async {
    _phone(tester);
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l3')));
    await _settle(tester);

    expect(find.text('Eʼlon'), findsOneWidget);
    expect(find.text('Bu meniki'), findsOneWidget);
    expect(find.text('Xaritada'), findsOneWidget);
    expect(find.text('Telefon raqamlar yashirin. Aloqa faqat ilova ichida.'), findsOneWidget);
    // The hidden detail never reaches this page.
    expect(find.textContaining('mushuk'), findsNothing);

    // Real timers: the mock repository waits with Future.delayed.
    await tester.runAsync(
      () => getIt<ClaimRepository>().submit(
        const SubmitClaimParams(listingId: 'l3', answer: 'Ichida rasm daftari bor, muqovasida mushuk'),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l3')));
    await _settle(tester);
    expect(find.text('Soʻrov yuborildi'), findsOneWidget);
    expect(find.text('Bu meniki'), findsNothing);
  });

  testWidgets('Author: claims card, mark returned', (tester) async {
    _phone(tester);
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l1')));
    await _settle(tester);

    expect(find.text('Mening eʼlonim'), findsOneWidget);
    expect(find.text('Faol'), findsOneWidget);
    expect(find.text('2 ta yangi soʻrov'), findsOneWidget);
    expect(find.text('Soʻrovlarni koʻrish · 2'), findsOneWidget);
    // Description and map row are for visitors only.
    expect(find.text('Xaritada'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Qaytarildi deb belgilash'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Ha, qaytarildi'));
    await _settle(tester);
    expect(find.text('Qaytarildi'), findsOneWidget);
    expect(find.text('Faol'), findsNothing);
    expect(find.bySemanticsLabel('Qaytarildi deb belgilash'), findsNothing);
  });

  testWidgets('Author: delete from the Yana menu', (tester) async {
    _phone(tester);
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l_mine_lost')));
    await _settle(tester);
    expect(find.text('Yoʻqolgan vaqt'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Yana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eʼlonni oʻchirish'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Oʻchirish'));
    await _settle(tester);

    expect(find.text('Mening eʼlonim'), findsNothing);
    final r = await tester.runAsync(() => getIt<ListingRepository>().getListing('l_mine_lost'));
    expect(r!.getLeft().toNullable(), isA<NotFoundFailure>());
  });
}
