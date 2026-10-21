import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_avatar.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../domain/entities/chat.dart';
import '../cubit/success_cubit.dart';
import '../../../../core/l10n/tr.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SuccessCubit>()..load(chatId),
      child: BlocBuilder<SuccessCubit, ViewState<ReturnSummary>>(
        builder: (context, state) => Scaffold(
          body: switch (state) {
            ViewLoading() || ViewEmpty() => const Center(child: CircularProgressIndicator()),
            ViewError() => SafeArea(child: ErrorState(onRetry: () => context.read<SuccessCubit>().load(chatId))),
            ViewLoaded(:final data) => _Content(summary: data),
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.summary});

  final ReturnSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final firstName = summary.finderName.split(' ').first;
    final owner = summary.owner;

    return Stack(
      children: [
        const Positioned.fill(child: _Confetti()),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(TSpace.xl, TSpace.x4l, TSpace.xl, TSpace.x2l),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight - TSpace.x4l - TSpace.x2l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(decoration: BoxDecoration(color: tc.successContainer, shape: BoxShape.circle)),
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(color: tc.success, shape: BoxShape.circle),
                              child: Icon(Symbols.handshake_rounded, size: 48, color: cs.surface),
                            ),
                            Positioned(
                              right: -6,
                              top: 20,
                              child: Transform.rotate(
                                angle: 0.17,
                                child: Material(
                                  elevation: 4,
                                  shadowColor: cs.scrim.withValues(alpha: 0.3),
                                  color: cs.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(TRadius.md),
                                  child: SizedBox.square(
                                    dimension: 48,
                                    child: Icon(Symbols.favorite_rounded, color: context.ts.placeholderIcon, fill: 1),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      summary.iAmFinder ? tr('Buyum egasiga qaytdi!') : tr('Buyumingiz qaytdi!'),
                      textAlign: TextAlign.center,
                      style: text.headlineMedium!.copyWith(fontSize: 30, height: 38 / 30, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      summary.iAmFinder
                          ? tr('{firstName}, bugun siz birovning kunini yaxshiladingiz. Halolligingiz uchun rahmat!', {'firstName': firstName})
                          : tr('{finderName} buyumingizni qaytardi. Unga rahmat aytishni unutmang!', {'finderName': summary.finderName}),
                      textAlign: TextAlign.center,
                      style: text.bodyLarge!.copyWith(fontSize: 17, height: 26 / 17, color: cs.secondary),
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
                        children: [
                          if (summary.ownerNote != null && summary.iAmFinder) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TAvatar(initials: TAvatar.initialsOf(owner.displayName), tone: AvatarTone.lost),
                                const SizedBox(width: TSpace.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tr('{displayName} yozdi', {'displayName': owner.displayName}),
                                          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '“${summary.ownerNote}”',
                                        style: const TextStyle(fontSize: 15, height: 22 / 15, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 14),
                          ],
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: tc.warningContainer,
                                  borderRadius: BorderRadius.circular(TRadius.md),
                                ),
                                child: Icon(Symbols.workspace_premium_rounded, color: tc.warning),
                              ),
                              const SizedBox(width: TSpace.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tr('Mehribon qoʻshni'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      tr('Siz {returnedCount} ta buyumni egasiga qaytardingiz', {'returnedCount': summary.returnedCount}),
                                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TSpace.x2l),
                    TButton.primary(label: tr('Lentaga qaytish'), onPressed: () => context.go(Routes.home)),
                    const SizedBox(height: TSpace.xs),
                    TButton.outline(
                      label: tr('Doʻstlarga ulashish'),
                      onPressed: () => TFeedback.success(context, tr('Havola nusxalandi')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Static confetti dots behind the hero.
class _Confetti extends StatelessWidget {
  const _Confetti();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    Widget bit(double l, double t, double w, double h, Color c, [double angle = 0]) => Positioned(
          left: l,
          top: t,
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(h / 2)),
            ),
          ),
        );
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, c) {
          final x = c.maxWidth / 390;
          return Stack(
            children: [
              bit(40 * x, 60, 10, 10, cs.primary),
              bit(320 * x, 90, 14, 6, tc.lost, 0.5),
              bit(80 * x, 250, 12, 5, tc.success, -0.44),
              bit(300 * x, 240, 9, 9, tc.warning),
              bit(190 * x, 36, 8, 8, tc.success),
              bit(30 * x, 170, 6, 14, tc.warning, 0.35),
              bit(345 * x, 180, 8, 8, cs.primary),
            ],
          );
        },
      ),
    );
  }
}
