import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/features/listing/presentation/pages/returned_stories_page.dart';
import 'package:topildi/features/listing/presentation/seen_returned.dart';

/// The feed's strip and the stories it opens, together: the one place where
/// a watched story has to reach the row behind it without upsetting a build
/// that is already running.
void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  Future<void> feed(WidgetTester tester) async {
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping an item opens its story, and watching it upsets nothing', (tester) async {
    getIt<SeenReturned>().seen.value = {};
    await feed(tester);

    expect(find.text('Egasiga qaytdi'), findsOneWidget);
    await tester.tap(find.text('Kalitlar toʻplami'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.byType(ReturnedStoriesPage), findsOneWidget);

    // Reported at the end of the frame, while the strip behind is listening.
    expect(getIt<SeenReturned>().contains('l_old'), isTrue);

    await tester.tap(find.byIcon(Symbols.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.byType(ReturnedStoriesPage), findsNothing);
  });
}
