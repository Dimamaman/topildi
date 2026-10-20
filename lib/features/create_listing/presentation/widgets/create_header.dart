import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Create-flow header: close/back, title, "n / 3" and a 3-segment progress bar.
class CreateHeader extends StatelessWidget implements PreferredSizeWidget {
  const CreateHeader({super.key, required this.title, this.step, this.isFirst = false, this.onLeading});

  final String title;

  /// 1-based step; null hides the counter and progress (Review).
  final int? step;
  final bool isFirst;
  final VoidCallback? onLeading;

  static const _steps = ['rasm va tur', 'maʼlumotlar', 'joy va sana'];

  @override
  // +1 for the bottom border.
  Size get preferredSize => Size.fromHeight(step == null ? 65 : 85);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLowest,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, step == null ? 8 : 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: isFirst ? 'Yopish' : 'Orqaga',
                        icon: Icon(isFirst ? Symbols.close_rounded : Symbols.arrow_back_rounded),
                        onPressed: onLeading ?? () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (step != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '$step / 3',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
                if (step != null) ...[
                  const SizedBox(height: 10),
                  Semantics(
                    label: '$step-qadam: ${_steps[step! - 1]}',
                    value: '$step / 3',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          for (var i = 1; i <= 3; i++) ...[
                            if (i > 1) const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i <= step! ? cs.primary : cs.outlineVariant,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
