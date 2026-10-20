import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/widgets/state_views.dart';

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
        title: 'Tez orada',
        body: 'Bu boʻlim ustida ishlayapmiz.',
        cta: showBack ? 'Orqaga' : null,
        onCta: () => Navigator.maybePop(context),
      ),
    );
  }
}
