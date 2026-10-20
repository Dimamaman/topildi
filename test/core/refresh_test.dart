import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/theme/topildi_theme.dart';
import 'package:topildi/core/widgets/t_refresh_scroll_view.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('${platform.name}: native pull-to-refresh calls onRefresh', (tester) async {
      var refreshed = 0;
      await tester.pumpWidget(MaterialApp(
        theme: topildiLight.copyWith(platform: platform),
        home: Scaffold(
          body: TRefreshScrollView(
            onRefresh: () async => refreshed++,
            slivers: [SliverList.list(children: [for (var i = 0; i < 30; i++) ListTile(title: Text('Qator $i'))])],
          ),
        ),
      ));

      final isIos = platform == TargetPlatform.iOS;
      // Idle refresh control has zero extent, so it counts as offstage.
      expect(find.byType(CupertinoSliverRefreshControl, skipOffstage: false), isIos ? findsOneWidget : findsNothing);
      expect(find.byType(RefreshIndicator), isIos ? findsNothing : findsOneWidget);

      await tester.fling(find.text('Qator 0'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(refreshed, 1);
    });
  }
}
