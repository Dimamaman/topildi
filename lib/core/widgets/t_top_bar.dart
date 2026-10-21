import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../l10n/tr.dart';

/// 60dp top bar: 48dp back button, centred title, optional trailing action.
class TTopBar extends StatelessWidget implements PreferredSizeWidget {
  const TTopBar({
    super.key,
    this.title,
    this.trailing,
    this.onBack,
    this.showBack = true,
    this.backIcon = Symbols.arrow_back_rounded,
    this.backLabel,
    this.bordered = false,
    this.background,
  });

  final String? title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack, bordered;
  final IconData backIcon;
  /// Defaults to "Orqaga".
  final String? backLabel;
  final Color? background;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: background ?? (bordered ? cs.surfaceContainerLowest : cs.surface),
      child: Container(
        decoration: bordered ? BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))) : null,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 48,
                    child: showBack
                        ? IconButton(
                            tooltip: backLabel ?? tr('Orqaga'),
                            icon: Icon(backIcon, size: 24),
                            onPressed: onBack ?? () => Navigator.maybePop(context),
                          )
                        : null,
                  ),
                  Expanded(
                    child: title == null
                        ? const SizedBox()
                        : Text(
                            title!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                  ),
                  if (trailing == null)
                    const SizedBox(width: 48, height: 48)
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      child: Center(widthFactor: 1, child: trailing),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sticky bottom action area with top border.
class TBottomBar extends StatelessWidget {
  const TBottomBar({super.key, required this.children, this.horizontal = 16});

  final List<Widget> children;
  final double horizontal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 10),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}
