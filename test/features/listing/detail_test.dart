import 'package:flutter/material.dart';
import 'package:topildi/features/listing/data/datasources/listing_remote_datasource.dart';
import 'package:topildi/features/claim/data/datasources/claim_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/config/features.dart';
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
    // The map row only shows while the map feature is on.
    expect(find.text('Xaritada'), Features.map ? findsOneWidget : findsNothing);
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
    await tester.tap(find.bySemanticsLabel('Ha, qaytarildi').last);
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
    await tester.tap(find.bySemanticsLabel('Oʻchirish').last);
    await _settle(tester);

    expect(find.text('Mening eʼlonim'), findsNothing);
    final r = await tester.runAsync(() => getIt<ListingRepository>().getListing('l_mine_lost'));
    expect(r!.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  testWidgets('Author: edit the title from Tahrirlash and save', (tester) async {
    _phone(tester);
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l_mine4')));
    await _settle(tester);

    await tester.tap(find.bySemanticsLabel('Tahrirlash'));
    await _settle(tester);
    expect(find.text('Eʼlonni tahrirlash'), findsOneWidget);
    expect(find.text('HAMMASI TAYYOR'), findsOneWidget);
    // Nothing changed yet: Saqlash does nothing.
    await tester.tap(find.text('Saqlash'));
    await tester.pump();
    expect(find.text('Saqlanmoqda…'), findsNothing);

    await tester.tap(find.text('Sarlavha va kategoriya'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Yangi sarlavha, tahrirlangan');
    await tester.tap(find.text('Tayyor'));
    await _settle(tester);

    await tester.tap(find.text('Saqlash'));
    // The loader capsule spins while saving: pump instead of settling.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _settle(tester);
    expect(find.text('Mening eʼlonim'), findsOneWidget);
    expect(find.text('Yangi sarlavha, tahrirlangan'), findsWidgets);
  });

  testWidgets('Author: hidden detail is locked once requests came in', (tester) async {
    _phone(tester);
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l_mine2')));
    await _settle(tester);

    await tester.tap(find.bySemanticsLabel('Tahrirlash'));
    await _settle(tester);
    expect(find.text('Soʻrovlar kelgan · oʻzgartirib boʻlmaydi'), findsOneWidget);
    await tester.tap(find.text('Yashirin belgi'));
    await tester.pump();
    expect(find.text('Soʻrovlar kelgan: yashirin belgini endi oʻzgartirib boʻlmaydi'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('Visitor: an unanswered claim can be taken back after 3 days', (tester) async {
    _phone(tester);
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l20')));
    await _settle(tester);
    expect(find.text('Soʻrov yuborildi'), findsOneWidget);

    await tester.tap(find.text('Soʻrov yuborildi'));
    await tester.pumpAndSettle();
    expect(find.text('Soʻrovni bekor qilasizmi?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Bekor qilish').last);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _settle(tester);
    expect(find.text('Soʻrov yuborildi'), findsNothing);
    expect(find.text('Bu meniki'), findsOneWidget);
    final t = await tester.runAsync(() => getIt<ClaimRepository>().getTarget('l20'));
    expect(t!.getRight().toNullable()!.attemptsLeft, 3);
  });

  testWidgets('Visitor: once my claim is accepted, Chatga oʻtish instead of Bu meniki', (tester) async {
    _phone(tester);
    // The author (someone else) accepts my waiting claim on l20.
    await tester.runAsync(() async {
      final claims = getIt<ClaimRemoteDataSource>();
      // An earlier test may have taken back the seeded claim: send one if needed.
      if (!(await claims.byClaimant('u_me', 'l20')).any((c) => c.status == ClaimStatus.pending)) {
        await getIt<ClaimRepository>().submit(
          const SubmitClaimParams(listingId: 'l20', answer: 'Ramkaning ichki tomonida tirnalgan joy bor'),
        );
      }
      final mine = await claims.byClaimant('u_me', 'l20');
      final listing = await getIt<ListingRemoteDataSource>().fetchById('l20');
      await claims.accept(mine.firstWhere((c) => c.status == ClaimStatus.pending), listing!);
    });
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.listing('l20')));
    await _settle(tester);
    expect(find.text('Chatga oʻtish'), findsOneWidget);
    expect(find.text('Bu meniki'), findsNothing);

    final t = await tester.runAsync(() => getIt<ClaimRepository>().getTarget('l20'));
    expect(t!.getRight().toNullable()!.accepted, isTrue);
    final again = await tester.runAsync(
      () => getIt<ClaimRepository>().submit(const SubmitClaimParams(listingId: 'l20', answer: 'Yana bir urinish javobi')),
    );
    expect(again!.getLeft().toNullable(), isA<ValidationFailure>());
  });
}
