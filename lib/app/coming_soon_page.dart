import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/widgets/state_views.dart';
import '../core/l10n/tr.dart';

/// Temporary page for screens that are not built yet.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, this.showBack = true});

  final String title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: showBack),
      body: EmptyState(
        icon: Symbols.construction_rounded,
        title: tr('Tez orada'),
        body: tr('Bu boʻlim ustida ishlayapmiz.'),
        cta: showBack ? tr('Orqaga') : null,
        onCta: () => Navigator.maybePop(context),
      ),
    );
  }
}
