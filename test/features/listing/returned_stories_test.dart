import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:topildi/features/listing/domain/entities/listing.dart';
import 'package:topildi/features/listing/domain/entities/returned_item.dart';
import 'package:topildi/features/listing/presentation/pages/returned_stories_page.dart';

/// "Egasiga qaytdi" stories: what one shows, how it moves on, and the one
/// name it may carry.
void main() {
  ReturnedItem item(String title, {String? finder, ItemCategory category = ItemCategory.keys}) => ReturnedItem(
    id: title,
    title: title,
    category: category,
    district: 'Chilonzor',
    returnedAt: DateTime.now().subtract(const Duration(hours: 2)),
    finderName: finder,
  );

  // No photos anywhere here: a story without one needs no network, and the
  // screen around it is the same either way.
  Future<void> open(WidgetTester tester, List<ReturnedItem> items, {int index = 0}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReturnedStoriesPage(args: ReturnedStoriesArgs(items: items, index: index)),
              ),
            ),
            child: const Text('ochish'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ochish'));
    // Pumped by hand, never settled: the story advances by itself every five
    // seconds, so pumpAndSettle would run the whole row and close the screen.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('one story shows the item, where and when — and nothing to do', (tester) async {
    await open(tester, [item('Uy kaliti')]);

    expect(find.text('Uy kaliti'), findsOneWidget);
    expect(find.text('Egasiga qaytdi'), findsOneWidget);
    expect(find.text('Kalitlar'), findsOneWidget);
    expect(find.text('Chilonzor'), findsOneWidget);
    expect(find.text('· 2 soat'), findsOneWidget);
    // No reply, no heart, no share: the listing is over.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('without consent the story names nobody', (tester) async {
    await open(tester, [item('Uy kaliti')]);
    expect(find.textContaining('Topuvchi'), findsNothing);
  });

  testWidgets('with consent it names the finder, and only the finder', (tester) async {
    await open(tester, [item('Qora hamyon', finder: 'Dinmuhammad D.')]);
    expect(find.textContaining('Topuvchi: Dinmuhammad D.'), findsOneWidget);
  });

  testWidgets('five seconds, then the next one by itself', (tester) async {
    await open(tester, [item('Birinchi'), item('Ikkinchi')]);
    expect(find.text('Birinchi'), findsOneWidget);

    await tester.pump(ReturnedStoriesPage.itemDuration);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Birinchi'), findsNothing);
    expect(find.text('Ikkinchi'), findsOneWidget);
  });

  testWidgets('the right two thirds go forward, the left third back', (tester) async {
    await open(tester, [item('Birinchi'), item('Ikkinchi')]);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;

    await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Ikkinchi'), findsOneWidget);

    await tester.tapAt(Offset(size.width * 0.1, size.height / 2));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Birinchi'), findsOneWidget);

    // There is nothing before the first: it only starts again.
    await tester.tapAt(Offset(size.width * 0.1, size.height / 2));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Birinchi'), findsOneWidget);
  });

  testWidgets('holding it stops the bars; letting go carries on', (tester) async {
    await open(tester, [item('Birinchi'), item('Ikkinchi')]);
    final centre = tester.getCenter(find.text('Birinchi'));

    final hold = await tester.startGesture(centre);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(ReturnedStoriesPage.itemDuration);
    // Still the first: nothing moves while the finger is down.
    expect(find.text('Birinchi'), findsOneWidget);

    await hold.up();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(ReturnedStoriesPage.itemDuration);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Ikkinchi'), findsOneWidget);
  });

  testWidgets('after the last one the screen closes by itself', (tester) async {
    await open(tester, [item('Yolgʻiz')]);
    await tester.pump(ReturnedStoriesPage.itemDuration);
    // Five seconds, then the closing transition.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Yolgʻiz'), findsNothing);
    expect(find.text('ochish'), findsOneWidget);
  });

  testWidgets('✕ closes it', (tester) async {
    await open(tester, [item('Yolgʻiz'), item('Ikkinchi')]);
    await tester.tap(find.byIcon(Symbols.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Yolgʻiz'), findsNothing);
    expect(find.text('ochish'), findsOneWidget);
  });

  for (final (width, scale) in [(360.0, 1.0), (360.0, 1.3)]) {
    testWidgets('a long title and the chips fit at ${width.toInt()} wide, text ×$scale', (tester) async {
      tester.view.physicalSize = Size(width * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await open(tester, [
        item(
          'Qora charm hamyon — ichida bank kartalari va haydovchilik guvohnomasi bor edi',
          finder: 'Dinmuhammad D.',
          category: ItemCategory.wallets,
        ),
      ]);
      // Any RenderFlex overflow would have failed the test by now.
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Qora charm hamyon'), findsOneWidget);
      expect(find.text('Hamyonlar'), findsOneWidget);
    });
  }

  testWidgets('each story says it has been watched, as it comes up', (tester) async {
    final watched = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ReturnedStoriesPage(
          args: ReturnedStoriesArgs(items: [item('Birinchi'), item('Ikkinchi')], onSeen: watched.add),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(watched, ['Birinchi']);

    // Moved on early: it was still seen.
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
    await tester.pump(const Duration(milliseconds: 16));
    expect(watched, ['Birinchi', 'Ikkinchi']);
  });

  testWidgets('it opens on the item that was tapped', (tester) async {
    await open(tester, [item('Birinchi'), item('Ikkinchi'), item('Uchinchi')], index: 2);
    expect(find.text('Uchinchi'), findsOneWidget);
  });
}
