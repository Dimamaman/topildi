import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../cubit/name_consent_cubit.dart';

/// "Ismim koʻrinsin": asked once, on "Buyum egasiga qaytdi!", right after the
/// person has done the thing worth naming.
///
/// Only the finder is ever named, and only from here: the owner's name is
/// not a setting anywhere, because it is never shown. Off is the default,
/// the switch saves itself, and the note says where to change it later.
class NameConsentCard extends StatelessWidget {
  const NameConsentCard({super.key, required this.displayName});

  /// The name as it would appear: "Ism F.".
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final cubit = context.read<NameConsentCubit>();
    final on = context.watch<NameConsentCubit>().state;
    final sub = TextStyle(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant).inter(FontWeight.w400);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x0F0F1420), offset: Offset(0, 10), blurRadius: 28)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            toggled: on,
            label: tr('Ismim koʻrinsin'),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => cubit.set(!on),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Ismim koʻrinsin'),
                          style: TextStyle(fontSize: 15, height: 20 / 15, color: cs.onSurface).inter(FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              for (final (i, part)
                                  in tr('“Egasiga qaytdi” lentasida: {name}').split('{name}').indexed) ...[
                                if (i > 0)
                                  TextSpan(
                                    text: displayName,
                                    style: TextStyle(color: cs.onSurface).inter(FontWeight.w600),
                                  ),
                                TextSpan(text: part),
                              ],
                            ],
                          ),
                          style: sub,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoSwitch(value: on, activeTrackColor: tc.primaryFill, onChanged: cubit.set),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 0.5, color: context.ts.separator),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Symbols.lock_rounded, size: 15, color: tc.onSurfaceMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tr('Egasining ismi hech qachon koʻrsatilmaydi. Keyin Profil → Sozlamalarda oʻzgartirish mumkin.'),
                  style: TextStyle(fontSize: 12, height: 17 / 12, color: tc.onSurfaceMuted).inter(FontWeight.w400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
