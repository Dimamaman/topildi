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
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/t_avatar.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../domain/entities/claim.dart';
import '../cubit/claims_cubit.dart';

/// Finder's view of "Bu meniki" requests for one of their listings.
class ClaimsPage extends StatelessWidget {
  const ClaimsPage({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ClaimsCubit>()..load(listingId),
      child: _ClaimsView(listingId: listingId),
    );
  }
}

class _ClaimsView extends StatelessWidget {
  const _ClaimsView({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClaimsCubit>();
    return BlocConsumer<ClaimsCubit, ClaimsState>(
      listenWhen: (a, b) => b.openedChatId != null || (b.actionFailure != null && a.actionFailure != b.actionFailure),
      listener: (context, state) {
        if (state.openedChatId != null) {
          context.push(Routes.chat(state.openedChatId!));
        } else if (state.actionFailure != null) {
          TFeedback.error(
            context,
            state.actionFailure is NetworkFailure ? 'Internet yoʻq. Qayta urinib koʻring' : 'Amalni bajarib boʻlmadi',
          );
        }
      },
      builder: (context, state) {
        final view = state.view;
        final review = view is ViewLoaded<ClaimReview> ? view.data : null;
        return Scaffold(
          appBar: _Header(
            title: review == null ? 'Soʻrovlar' : 'Soʻrovlar · ${review.claims.length}',
            subtitle: review?.listing.title,
          ),
          body: switch (view) {
            ViewLoading() => const CardsSkeleton(count: 2),
            ViewEmpty() => EmptyState(
                icon: Symbols.shield_rounded,
                title: 'Hali soʻrov yoʻq',
                body: 'Kimdir “Bu meniki” desa, darhol xabar beramiz.',
                cta: 'Eʼlonni ulashish',
                onCta: () => TFeedback.success(context, 'Havola nusxalandi'),
              ),
            ViewError(:final failure, :final isOffline) => isOffline
                ? OfflineState(onRetry: () => cubit.load(listingId))
                : failure is ForbiddenFailure
                    ? const EmptyState(
                        icon: Symbols.lock_rounded,
                        title: 'Ruxsat yoʻq',
                        body: 'Soʻrovlarni faqat eʼlon muallifi koʻra oladi.',
                      )
                    : ErrorState(onRetry: () => cubit.load(listingId)),
            ViewLoaded(:final data) => _List(review: data, busyId: state.busyId),
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget implements PreferredSizeWidget {
  const _Header({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLowest,
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Orqaga',
                    icon: const Icon(Symbols.arrow_back_rounded),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
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

class _List extends StatelessWidget {
  const _List({required this.review, required this.busyId});

  final ClaimReview review;
  final String? busyId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: TSpace.screen, vertical: TSpace.md),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.ts.primaryTint,
            borderRadius: BorderRadius.circular(TRadius.md),
            border: Border.all(color: cs.primary, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Symbols.lock_rounded, size: 16, color: cs.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Siz yozgan yashirin belgi',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(review.hiddenDetail, style: const TextStyle(fontSize: 16, height: 23 / 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Javoblarni belgi bilan solishtiring. Toʻgʻri javob bergan odamni qabul qiling.',
          style: TextStyle(fontSize: 14, height: 20 / 14, color: cs.secondary),
        ),
        for (final c in review.claims) ...[
          const SizedBox(height: 14),
          _ClaimCard(claim: c, busy: busyId == c.id, disabled: busyId != null && busyId != c.id),
        ],
      ],
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim, required this.busy, required this.disabled});

  final Claim claim;
  final bool busy, disabled;

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Hozirgina';
    if (d.inMinutes < 60) return '${d.inMinutes} daqiqa oldin';
    if (d.inHours < 24) return '${d.inHours} soat oldin';
    return '${d.inDays} kun oldin';
  }

  Future<void> _reject(BuildContext context) async {
    final ok = await TFeedback.confirm(
      context,
      title: 'Soʻrovni rad etasizmi?',
      body: 'Javob yashirin belgiga mos kelmadi. Foydalanuvchiga xabar beramiz.',
      confirmLabel: 'Rad etish',
      destructive: true,
    );
    if (ok && context.mounted) context.read<ClaimsCubit>().reject(claim.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rejected = claim.status == ClaimStatus.rejected;
    final pending = claim.status == ClaimStatus.pending;
    final (kind, tone) = switch (claim.status) {
      ClaimStatus.pending => (StatusKind.pending, AvatarTone.lost),
      ClaimStatus.accepted => (StatusKind.accepted, AvatarTone.primary),
      ClaimStatus.rejected => (StatusKind.rejected, AvatarTone.neutral),
    };

    return Opacity(
      opacity: rejected ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(TRadius.md),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TAvatar(initials: TAvatar.initialsOf(claim.claimant.displayName), tone: tone),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(claim.claimant.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 1),
                      Text(_ago(claim.createdAt), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                StatusBadge(kind: kind, size: BadgeSize.small),
              ],
            ),
            const SizedBox(height: TSpace.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Javobi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                      if (claim.hasProofPhoto) ...[
                        const Spacer(),
                        Icon(Symbols.image_rounded, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('Dalil rasm', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(claim.answer, style: const TextStyle(fontSize: 15, height: 22 / 15)),
                  if (claim.proofPath != null) ...[
                    const SizedBox(height: TSpace.xs),
                    PhotoPlaceholder(
                      icon: Symbols.image_rounded,
                      path: claim.proofPath,
                      height: 120,
                      width: double.infinity,
                    ),
                  ],
                ],
              ),
            ),
            if (pending) ...[
              const SizedBox(height: TSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: TButton.danger(label: 'Rad etish', onPressed: disabled || busy ? null : () => _reject(context)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TButton.primary(
                      label: 'Qabul qilish',
                      loading: busy,
                      onPressed: disabled ? null : () => context.read<ClaimsCubit>().accept(claim.id),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
