import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/photo_source_sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../../core/widgets/t_top_bar.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/claim.dart';
import '../cubit/claim_cubit.dart';
import 'claim_sent_page.dart';
import '../../../../core/l10n/tr.dart';

class ClaimPage extends StatelessWidget {
  const ClaimPage({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ClaimCubit>()..load(listingId),
      child: _ClaimView(listingId: listingId),
    );
  }
}

class _ClaimView extends StatelessWidget {
  const _ClaimView({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClaimCubit>();
    return BlocConsumer<ClaimCubit, ClaimState>(
      listenWhen: (a, b) => a.sent != b.sent || a.submitFailure != b.submitFailure,
      listener: (context, state) {
        if (state.sent) {
          final target = state.view;
          final listing = target is ViewLoaded<ClaimTarget> ? target.data.listing : null;
          context.pushReplacement(
            Routes.claimSent(listingId),
            extra: ClaimSentArgs(authorName: listing?.author.displayName, lost: listing != null && !listing.isFound),
          );
        } else if (state.submitFailure != null) {
          TFeedback.error(
            context,
            switch (state.submitFailure) {
              NetworkFailure() => tr('Internet yoʻq. Qayta urinib koʻring'),
              ValidationFailure(:final message) => message ?? tr('Soʻrovni yuborib boʻlmadi'),
              _ => tr('Soʻrovni yuborib boʻlmadi'),
            },
          );
        }
      },
      builder: (context, state) {
        final view = state.view;
        return Scaffold(
          appBar: TTopBar(
            title: view is ViewLoaded<ClaimTarget> && !view.data.listing.isFound
                ? tr('Buyum sizda ekanini tasdiqlang')
                : tr('Egaligingizni tasdiqlang'),
            bordered: true,
          ),
          body: switch (view) {
            ViewLoading() || ViewEmpty() => const Center(child: CircularProgressIndicator()),
            ViewError(:final isOffline) => isOffline
                ? OfflineState(onRetry: () => cubit.load(listingId))
                : ErrorState(onRetry: () => cubit.load(listingId)),
            ViewLoaded(:final data) => _Form(target: data, state: state),
          },
          bottomNavigationBar: view is ViewLoaded<ClaimTarget>
              ? _Footer(attemptsLeft: view.data.attemptsLeft, lost: !view.data.listing.isFound, submitting: state.submitting)
              : null,
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.target, required this.state});

  final ClaimTarget target;
  final ClaimState state;

  static const _hints = ['Ichidagi narsalar', 'Rang yoki naqsh', 'Yozuv, stiker', 'Tirnalgan joy'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<ClaimCubit>();
    final l = target.listing;
    // A "lost" listing is answered by someone who found the item: they prove
    // they hold it by naming the owner's hidden detail.
    final lost = !l.isFound;
    final error = state.answerError;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: TSpace.screen, vertical: TSpace.md),
      children: [
        Container(
          padding: const EdgeInsets.all(TSpace.xs),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(TRadius.md),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              PhotoPlaceholder(icon: l.category.icon, tint: l.tint, width: 52, height: 52, iconSize: 24),
              const SizedBox(width: TSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      lost
                          ? tr('Egasi: {name} · {area}', {'name': l.author.displayName, 'area': l.areaName.split(',').first})
                          : tr('Topuvchi: {name} · {area}', {'name': l.author.displayName, 'area': l.areaName.split(',').first}),
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TSpace.md),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.ts.primaryTint, borderRadius: BorderRadius.circular(TRadius.md)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                child: Icon(Symbols.shield_lock_rounded, size: 20, color: cs.onPrimary),
              ),
              const SizedBox(width: TSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Nega bu savol?'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      lost
                          ? tr('Egasi buyumning faqat oʻzi biladigan bir belgisini yashirib qoʻygan. Buyumga qarab uni toʻgʻri aytsangiz, buyum haqiqatan sizda ekani tasdiqlanadi. Bu soxta xabarlarning oldini oladi.')
                          : tr('Topuvchi buyumning faqat egasi biladigan bir belgisini yashirib qoʻygan. Uni toʻgʻri aytsangiz, buyum sizniki ekani tasdiqlanadi. Bu begonalar olib ketishining oldini oladi.'),
                      style: TextStyle(fontSize: 14, height: 20 / 14, color: cs.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TSpace.md),
        Text(lost ? tr('Buyumda qanday belgi bor?') : tr('Buyumingizda qanday belgi bor?'),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: error != null ? cs.error : null)),
        const SizedBox(height: TSpace.xs),
        TextField(
          onChanged: cubit.setAnswer,
          minLines: 4,
          maxLines: 6,
          maxLength: 300,
          enabled: target.attemptsLeft > 0,
          style: const TextStyle(fontSize: 15, height: 22 / 15),
          decoration: InputDecoration(
            hintText: lost ? tr('Masalan: brelokda qizil yulduzcha bor') : tr('Masalan: ichida koʻk rangli bank kartam bor'),
            counterText: '',
            errorText: error,
            errorMaxLines: 2,
          ),
        ),
        const SizedBox(height: TSpace.md),
        Text(tr('Nimani yozish mumkin:'), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        const SizedBox(height: TSpace.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final h in _hints)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(TRadius.sm)),
                child: Text(tr(h), style: TextStyle(fontSize: 13, color: cs.secondary)),
              ),
          ],
        ),
        const SizedBox(height: TSpace.md),
        if (state.proofPath != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(TRadius.md),
            child: PhotoPlaceholder(icon: Symbols.image_rounded, path: state.proofPath, height: 140, width: double.infinity),
          ),
          const SizedBox(height: TSpace.xs),
        ],
        Builder(
          builder: (anchor) => _ProofButton(
            attached: state.hasProofPhoto,
            onTap: () async {
              if (state.hasProofPhoto) return cubit.setProofPhoto(null);
              final path = await pickPhoto(context, anchor: anchor, title: tr('Dalil rasm'));
              if (path != null) cubit.setProofPhoto(path);
            },
          ),
        ),
      ],
    );
  }
}

class _ProofButton extends StatelessWidget {
  const _ProofButton({required this.attached, required this.onTap});

  final bool attached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    return Material(
      color: attached ? tc.successContainer : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TRadius.md),
        side: BorderSide(color: attached ? tc.success : cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: TSize.button,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(attached ? Symbols.check_circle_rounded : Symbols.add_photo_alternate_rounded,
                  size: 20, color: attached ? tc.success : cs.onSurface),
              const SizedBox(width: TSpace.xs),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: attached ? tr('Dalil rasmni olib tashlash') : tr('Dalil rasm qoʻshish '),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: attached ? tc.success : cs.onSurface),
                    children: [
                      if (!attached)
                        TextSpan(
                          text: tr('(ixtiyoriy)'),
                          style: TextStyle(fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.attemptsLeft, required this.lost, required this.submitting});

  final int attemptsLeft;
  final bool lost;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final none = attemptsLeft <= 0;
    return TBottomBar(
      horizontal: TSpace.screen,
      children: [
        Text(
          none
              ? tr('Urinishlar tugadi')
              : lost
              ? tr('{attemptsLeft} ta urinishingiz bor · Javobni faqat egasi koʻradi', {'attemptsLeft': attemptsLeft})
              : tr('{attemptsLeft} ta urinishingiz bor · Javobni faqat topuvchi koʻradi', {'attemptsLeft': attemptsLeft}),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: none ? cs.error : cs.onSurfaceVariant),
        ),
        const SizedBox(height: TSpace.xs),
        TButton.primary(
          label: tr('Soʻrov yuborish'),
          loading: submitting,
          onPressed: none ? null : context.read<ClaimCubit>().submit,
        ),
      ],
    );
  }
}
