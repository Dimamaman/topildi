import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Feed loads and shows found listings', (tester) async {
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    expect(find.text('Lenta'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Qora charm hamyon'), findsOneWidget);

    await tester.tap(find.text('Yoʻqolgan').first);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Pasport, koʻk muqovali'), findsOneWidget);
  });
}
