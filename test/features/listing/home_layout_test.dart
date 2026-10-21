import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  for (final (width, scale) in [(360.0, 1.0), (360.0, 1.3), (393.0, 1.3)]) {
    testWidgets('Lenta lays out at ${width.toInt()} wide, text ×$scale', (tester) async {
      tester.view.physicalSize = Size(width * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Qora charm hamyon'), findsOneWidget);
      await tester.drag(find.text('Qora charm hamyon'), const Offset(0, -400));
      await tester.pumpAndSettle();
      // Any RenderFlex overflow would have failed the test by now.
      expect(tester.takeException(), isNull);
    });
  }
}
