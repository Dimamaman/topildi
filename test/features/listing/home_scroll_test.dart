import 'package:flutter/foundation.dart';
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

/// Opacity of the inline "Lenta" in the pinned glass bar.
double _inlineTitleOpacity(WidgetTester t) {
  final inline = find.ancestor(of: find.text('Lenta'), matching: find.byType(Opacity));
  return t.widget<Opacity>(inline.first).opacity;
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('${platform.name}: large title collapses, glass buttons and tabs stay pinned', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
      await _settle(tester);

      final bell = find.bySemanticsLabel(RegExp('^Bildirishnomalar'));
      final bellTop = tester.getTopLeft(bell).dy;
      final tabsTop = tester.getTopLeft(find.text('Topilgan').first).dy;
      expect(_inlineTitleOpacity(tester), 0);

      await tester.drag(find.text('Qora charm hamyon'), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Buttons did not move; the inline title replaced the large one.
      expect(tester.getTopLeft(bell).dy, bellTop);
      expect(_inlineTitleOpacity(tester), 1);
      // Tabs and chips pinned right under the buttons.
      final pinnedTabs = tester.getTopLeft(find.text('Yoʻqolgan').first).dy;
      expect(pinnedTabs, lessThan(tabsTop));
      expect(pinnedTabs, greaterThan(bellTop + 44));
      expect(find.text('Hammasi').hitTestable(), findsOneWidget);

      // Pinned tabs still work.
      await tester.tap(find.text('Yoʻqolgan').first);
      await _settle(tester);
      // Cards now carry the Yoʻqolgan tag (plus the segment label).
      expect(find.text('Yoʻqolgan'), findsAtLeastNWidgets(2));
      expect(find.text('Topilgan'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
