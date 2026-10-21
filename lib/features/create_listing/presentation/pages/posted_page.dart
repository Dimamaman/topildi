import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/t_button.dart';
import '../cubit/create_flow_cubit.dart';
import '../../../../core/l10n/tr.dart';

class PostedPage extends StatelessWidget {
  const PostedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final state = context.read<CreateFlowCubit>().state;
    final id = state.postedId;
    final isFound = state.draft.isFound;
    final steps = isFound
        ? [
            tr('Soʻrov kelsa, javobni yashirin belgi bilan solishtirasiz.'),
            tr('Mos kelsa, qabul qilasiz va chatda uchrashuvni kelishasiz.'),
            tr('Buyumni gavjum, xavfsiz joyda topshirasiz.'),
          ]
        : [
            tr('Mos eʼlon chiqsa yoki kimdir topsa, darhol xabar beramiz.'),
            tr('Topuvchi bilan faqat ilova ichidagi chatda yozishasiz.'),
            tr('Buyumni gavjum, xavfsiz joyda olasiz.'),
          ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(TSpace.xl, 56, TSpace.xl, TSpace.x2l),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 56 - TSpace.x2l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(color: tc.successContainer, shape: BoxShape.circle),
                              child: Center(child: Icon(Symbols.check_rounded, size: 56, color: tc.success, weight: 600)),
                            ),
                            Positioned(left: -10, top: 18, child: _dot(10, cs.primary)),
                            Positioned(right: -6, bottom: 14, child: _dot(14, tc.success)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(tr('Eʼlon joylandi!'), textAlign: TextAlign.center, style: text.headlineMedium),
                    const SizedBox(height: 18),
                    Text(
                      isFound
                          ? tr('Rahmat! Endi egasi sizni topa oladi. Kimdir “Bu meniki” desa, darhol xabar beramiz.')
                          : tr('Eʼloningizni hamma koʻradi. Kimdir buyumingizni topsa, darhol xabar beramiz.'),
                      textAlign: TextAlign.center,
                      style: text.bodyLarge!.copyWith(color: cs.secondary),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(TSpace.md),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(TRadius.lg),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('Keyin nima boʻladi?'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          for (var i = 0; i < steps.length; i++) ...[
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                                  child: Text('${i + 1}',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
                                ),
                                const SizedBox(width: TSpace.sm),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(steps[i], style: TextStyle(fontSize: 14, height: 20 / 14, color: cs.secondary)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: TSpace.x2l),
                    TButton.primary(
                      label: tr('Eʼlonni koʻrish'),
                      onPressed: id == null
                          ? null
                          // Detail's back button falls back to the feed when nothing is below it.
                          : () => context.go(Routes.listing(id)),
                    ),
                    const SizedBox(height: TSpace.xs),
                    TButton.text(label: tr('Lentaga qaytish'), expand: true, onPressed: () => context.go(Routes.home)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
