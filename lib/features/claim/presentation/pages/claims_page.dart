import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/glass_empty_icon.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../../core/widgets/topildi_loader.dart';
import '../../../create_listing/presentation/widgets/create_ui.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/claim.dart';
import '../../domain/usecases/reject_claim.dart';
import '../cubit/claims_cubit.dart';
import '../../../../core/l10n/tr.dart';

/// Finder's view of the requests on one of their listings, "hidden detail
/// vs answer": each request is one card with the detail they wrote above
/// the claimant's answer; "Mos emas" / "Qabul qilish" at the bottom act on
/// the card in view. Several requests page sideways.
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

class _ClaimsView extends StatefulWidget {
  const _ClaimsView({required this.listingId});

  final String listingId;

  @override
  State<_ClaimsView> createState() => _ClaimsViewState();
}

class _ClaimsViewState extends State<_ClaimsView> {
  final _pages = PageController(viewportFraction: 0.92);
  int _page = 0;

  /// "Mos emas" waits 5 s for "Bekor qilish" before it is sent.
  String? _undoId;
  Timer? _undo;

  @override
  void dispose() {
    // Leaving during the undo window still sends the rejection.
    if (_undo?.isActive ?? false) {
      _undo!.cancel();
      unawaited(getIt<RejectClaim>()(_undoId!));
    }
    _pages.dispose();
    super.dispose();
  }

  /// Waiting first, then accepted, then rejected; newest first within each.
  static List<Claim> _ordered(List<Claim> claims) {
    int rank(ClaimStatus s) => switch (s) {
      ClaimStatus.pending => 0,
      ClaimStatus.accepted => 1,
      _ => 2,
    };
    return [...claims]..sort((a, b) {
      final r = rank(a.status).compareTo(rank(b.status));
      return r != 0 ? r : b.createdAt.compareTo(a.createdAt);
    });
  }

  void _reject(Claim claim) {
    _commitUndo();
    setState(() => _undoId = claim.id);
    final messenger = ScaffoldMessenger.of(context);
    _undo = Timer(const Duration(seconds: 5), () async {
      // A snackbar with an action stays until closed.
      messenger.hideCurrentSnackBar();
      final cubit = context.read<ClaimsCubit>();
      await cubit.reject(claim.id);
      if (!mounted) return;
      setState(() => _undoId = null);
      if (cubit.state.actionFailure != null) {
        TFeedback.error(context, tr('Amalni bajarib boʻlmadi'));
      }
    });
    TFeedback.success(
      context,
      tr('Javob mos emas deb belgilandi'),
      action: tr('Bekor qilish'),
      onAction: () {
        _undo?.cancel();
        if (mounted) setState(() => _undoId = null);
      },
    );
  }

  /// A second "Mos emas" before the first one's window ends sends the first.
  void _commitUndo() {
    if (!(_undo?.isActive ?? false)) return;
    _undo!.cancel();
    context.read<ClaimsCubit>().reject(_undoId!);
  }

  Future<void> _accept(Claim claim) async {
    final cubit = context.read<ClaimsCubit>();
    final ok = await TFeedback.confirm(
      context,
      title: tr('{name}ni qabul qilasizmi?', {'name': claim.claimant.displayName}),
      body: tr('Chat ochiladi. Uchrashuvni gavjum, xavfsiz joyda belgilang.'),
      confirmLabel: tr('Qabul qilish'),
      cancelLabel: tr('Bekor'),
    );
    if (!ok || !mounted) return;
    await TopildiLoader.run<Failure?>(
      context,
      task: () async {
        await cubit.accept(claim.id);
        return cubit.state.actionFailure;
      },
      failureOf: (f) => f,
      icon: Symbols.check_rounded,
      label: tr('Qabul qilinmoqda…'),
      errorLabel: tr('Qabul qilib boʻlmadi'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClaimsCubit>();
    final mq = MediaQuery.of(context);
    final top = math.max(58.0, mq.padding.top + 4);
    return BlocConsumer<ClaimsCubit, ClaimsState>(
      // Accepting opens the chat (the loader capsule shows any failure).
      listenWhen: (a, b) => b.openedChatId != null && a.openedChatId != b.openedChatId,
      listener: (context, state) => context.push(Routes.chat(state.openedChatId!)),
      builder: (context, state) {
        final view = state.view;
        final review = view is ViewLoaded<ClaimReview> ? view.data : null;
        final claims = review == null ? const <Claim>[] : _ordered(review.claims);
        final page = claims.isEmpty ? 0 : _page.clamp(0, claims.length - 1);
        final current = claims.isEmpty ? null : claims[page];
        final title = claims.length > 1
            ? tr('Soʻrovlar · {i} / {n}', {'i': page + 1, 'n': claims.length})
            : tr('Soʻrovlar · {n}', {'n': claims.length});
        return Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: CreateBackground()),
              Positioned.fill(
                top: top + 44 + 20,
                child: switch (view) {
                  ViewLoading() => const Center(child: CircularProgressIndicator.adaptive()),
                  ViewEmpty() => const _Empty(),
                  ViewError(:final failure, :final isOffline) =>
                    isOffline
                        ? OfflineState(onRetry: () => cubit.load(widget.listingId))
                        : failure is ForbiddenFailure
                        ? EmptyState(
                            icon: Symbols.lock_rounded,
                            title: tr('Ruxsat yoʻq'),
                            body: tr('Soʻrovlarni faqat eʼlon muallifi koʻra oladi.'),
                          )
                        : ErrorState(onRetry: () => cubit.load(widget.listingId)),
                  ViewLoaded(:final data) => _Cards(
                    review: data,
                    claims: claims,
                    controller: _pages,
                    page: page,
                    undoId: _undoId,
                    onPage: (i) => setState(() => _page = i),
                  ),
                },
              ),
              if (current != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _Actions(
                    claim: current,
                    undone: current.id == _undoId,
                    busy: state.busyId != null,
                    onReject: () => _reject(current),
                    onAccept: () => _accept(current),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                top: top,
                child: _Bar(title: review == null ? tr('Soʻrovlar') : title, listing: review?.listing),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Back, "Soʻrovlar · N" over the listing's title, and its thumbnail.
class _Bar extends StatelessWidget {
  const _Bar({required this.title, required this.listing});

  final String title;
  final Listing? listing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = listing;
    return Row(
      children: [
        CreateGlassButton(
          icon: Symbols.arrow_back_rounded,
          label: tr('Orqaga'),
          onTap: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 17, height: 22 / 17, color: cs.onSurface).inter(FontWeight.w700),
                ),
              ),
              if (l != null)
                Text(
                  l.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, height: 16 / 12, color: cs.onSurfaceVariant).inter(FontWeight.w400),
                ),
            ],
          ),
        ),
        if (l != null) ...[
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: l.title,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => context.push(Routes.listing(l.id)),
              child: PhotoPlaceholder(
                icon: l.category.icon,
                tint: l.tint,
                path: l.photos.isEmpty ? null : l.photos.first,
                width: 44,
                height: 44,
                iconSize: 24,
                radius: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GlassEmptyIcon(icon: Symbols.front_hand_rounded, iconSize: 60, badge: GlassIconBadge.none),
            const SizedBox(height: 20),
            Text(
              tr('Hali soʻrov yoʻq'),
              textAlign: TextAlign.center,
              style: text.headlineSmall!
                  .copyWith(fontSize: 24, height: 30 / 24, letterSpacing: -0.4, color: cs.onSurface)
                  .inter(FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              tr('Egasi yashirin belgini aytsa, soʻrov shu yerda paydo boʻladi.'),
              textAlign: TextAlign.center,
              style: text.bodyMedium!
                  .copyWith(fontSize: 15, height: 21 / 15, color: cs.onSurfaceVariant)
                  .inter(FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

/// The hint, then one page per request (dots under several).
class _Cards extends StatelessWidget {
  const _Cards({
    required this.review,
    required this.claims,
    required this.controller,
    required this.page,
    required this.undoId,
    required this.onPage,
  });

  final ClaimReview review;
  final List<Claim> claims;
  final PageController controller;
  final int page;
  final String? undoId;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final many = claims.length > 1;
    // Room for the buttons under the content.
    final bottom = math.max(34.0, MediaQuery.viewPaddingOf(context).bottom) + 56 + 24;
    Widget pageOf(int i) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(many ? 4 : 16, 0, many ? 4 : 16, bottom + (many ? 24 : 0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ClaimCard(claim: claims[i], hiddenDetail: review.hiddenDetail, undone: claims[i].id == undoId),
          const SizedBox(height: 24),
          _Note(claim: claims[i]),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            tr('Javobni oʻzingiz yozgan belgi bilan solishtiring. Mos kelsa — qabul qiling.'),
            style: TextStyle(fontSize: 14, height: 20 / 14, color: cs.secondary).inter(FontWeight.w400),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: many
              ? Stack(
                  children: [
                    PageView.builder(
                      controller: controller,
                      itemCount: claims.length,
                      onPageChanged: onPage,
                      itemBuilder: (_, i) => pageOf(i),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: bottom - 8,
                      child: _Dots(count: claims.length, active: page),
                    ),
                  ],
                )
              : pageOf(0),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count, active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == active ? cs.primary : cs.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One request: who and when, their status, the detail you wrote "VS"
/// their answer, and the proof photo line.
class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim, required this.hiddenDetail, required this.undone});

  final Claim claim;
  final String hiddenDetail;

  /// "Mos emas" tapped, still undoable: shown as rejected already.
  final bool undone;

  /// Avatar (background, letter) colours, stable per name.
  static (Color, Color) _tone(BuildContext context, String name) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final tones = [
      (tc.lostContainer, tc.lost),
      (cs.primaryContainer, cs.primary),
      (tc.successContainer, tc.success),
      (
        Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2E2742) : const Color(0xFFEBE6F3),
        Theme.of(context).brightness == Brightness.dark ? const Color(0xFFC2B5E8) : const Color(0xFF5B4A8A),
      ),
    ];
    return tones[name.codeUnits.fold(0, (a, b) => a + b) % tones.length];
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return tr('Hozirgina');
    if (d.inMinutes < 60) return tr('{n} daqiqa oldin', {'n': d.inMinutes});
    if (d.inHours < 24) return tr('{n} soat oldin', {'n': d.inHours});
    return tr('{n} kun oldin', {'n': d.inDays});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = claim.claimant.displayName;
    final status = undone ? ClaimStatus.rejected : claim.status;
    final (chipBg, chipFg, chipLabel) = switch (status) {
      ClaimStatus.pending => (tc.warningContainer, tc.warning, tr('Kutilmoqda')),
      ClaimStatus.accepted => (cs.primaryContainer, cs.onPrimaryContainer, tr('Qabul qilindi')),
      _ => (cs.errorContainer, cs.error, tr('Rad etildi')),
    };
    final (avatarBg, avatarFg) = _tone(context, name);
    final label = TextStyle(fontSize: 12, height: 16 / 12, letterSpacing: 0.8).inter(FontWeight.w700);
    final body = TextStyle(fontSize: 17, height: 23 / 17).inter(FontWeight.w600);

    return Opacity(
      opacity: status == ClaimStatus.rejected ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: dark ? const Color(0x66000000) : const Color(0x120F1420),
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
                  child: Text(
                    name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
                    style: TextStyle(fontSize: 18, color: avatarFg).inter(FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: cs.onSurface).inter(FontWeight.w700),
                      ),
                      Text(
                        '${_ago(claim.createdAt)} · ${tr('{n}-urinish', {'n': claim.attempt})}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant).inter(FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: chipFg, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(chipLabel, style: TextStyle(fontSize: 12, color: chipFg).inter(FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The hidden detail: the app's soft blue, with a primary ring.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Symbols.lock_rounded, size: 15, fill: 1, color: cs.primary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  tr('Siz yozgan belgi').toUpperCase(),
                                  style: label.copyWith(color: cs.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(hiddenDetail, style: body.copyWith(color: cs.onSurface)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: cs.outlineVariant, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Symbols.front_hand_rounded, size: 15, color: cs.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  tr('{name} javobi', {'name': name}).toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: label.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ),
                              // Keeps the label clear of the VS badge.
                              const SizedBox(width: 40),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(claim.answer, style: body.copyWith(color: cs.onSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
                // VS between the two cards, 18 from the right edge.
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(padding: const EdgeInsets.only(right: 18), child: _Vs()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Proof(claim: claim),
          ],
        ),
      ),
    );
  }
}

class _Vs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF2A3550) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x260F1420), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Text(
          'VS',
          style: TextStyle(
            fontSize: 12,
            color: dark ? const Color(0xFFC2CBDB) : const Color(0xFF556070),
          ).inter(FontWeight.w800),
        ),
      ),
    );
  }
}

/// "Dalil rasm yoʻq · …", or the proof photo (tap for full screen).
class _Proof extends StatelessWidget {
  const _Proof({required this.claim});

  final Claim claim;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 12, height: 16 / 12, color: cs.onSurfaceVariant).inter(FontWeight.w400);
    final path = claim.proofPath;
    if (path == null) {
      return Row(
        children: [
          Icon(Symbols.photo_rounded, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(tr('Dalil rasm yoʻq · Qabul qilsangiz, chat ochiladi'), style: style)),
        ],
      );
    }
    return Semantics(
      button: true,
      label: tr('Dalil rasm'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          barrierColor: Colors.black87,
          builder: (dialog) => GestureDetector(
            onTap: () => Navigator.pop(dialog),
            child: InteractiveViewer(
              child: Center(
                child: PhotoPlaceholder(icon: Symbols.image_rounded, path: path, radius: 0),
              ),
            ),
          ),
        ),
        child: Row(
          children: [
            PhotoPlaceholder(icon: Symbols.image_rounded, path: path, width: 56, height: 56, iconSize: 24, radius: 12),
            const SizedBox(width: 10),
            Text(tr('Dalil rasm'), style: style),
          ],
        ),
      ),
    );
  }
}

/// What "Mos emas" costs the claimant.
class _Note extends StatelessWidget {
  const _Note({required this.claim});

  final Claim claim;

  @override
  Widget build(BuildContext context) {
    if (claim.status != ClaimStatus.pending) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final left = ClaimTarget.maxAttempts - claim.attempt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.info_rounded, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              left > 0
                  ? tr('“Mos emas” desangiz, unda yana {n} ta urinish qoladi. Ismingiz va raqamingiz koʻrsatilmaydi.', {
                      'n': left,
                    })
                  : tr('Bu uning oxirgi urinishi. Ismingiz va raqamingiz koʻrsatilmaydi.'),
              style: TextStyle(fontSize: 12, height: 17 / 12, color: cs.onSurfaceVariant).inter(FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom buttons for the request in view: "Mos emas" + "Qabul qilish"
/// while it waits, "Chatga oʻtish" once accepted, nothing once rejected.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.claim,
    required this.undone,
    required this.busy,
    required this.onReject,
    required this.onAccept,
  });

  final Claim claim;
  final bool undone, busy;
  final VoidCallback onReject, onAccept;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pending = claim.status == ClaimStatus.pending && !undone;
    final accepted = claim.status == ClaimStatus.accepted;
    if (!pending && !accepted) return const SizedBox.shrink();
    final bottom = math.max(34.0, MediaQuery.viewPaddingOf(context).bottom);
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.surface.withValues(alpha: 0), cs.surface],
                  stops: const [0, 0.35],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 40, 20, bottom),
          child: accepted
              ? CreatePrimaryButton(
                  label: tr('Chatga oʻtish'),
                  leadingIcon: Symbols.forum_rounded,
                  // The chat has the claim's id.
                  onTap: () => context.push(Routes.chat(claim.id)),
                )
              : Row(
                  children: [
                    // 1 : 1.3, as in the design.
                    Expanded(flex: 10, child: _RejectButton(onTap: busy ? null : onReject)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 13,
                      child: CreatePrimaryButton(
                        label: tr('Qabul qilish'),
                        leadingIcon: Symbols.check_rounded,
                        onTap: busy ? null : onAccept,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// "✕ Mos emas": soft red capsule.
class _RejectButton extends StatelessWidget {
  const _RejectButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF3A1C1A) : const Color(0xFFFDECEA);
    final fg = dark ? const Color(0xFFFF8A80) : const Color(0xFFC2362B);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: tr('Mos emas'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.close_rounded, size: 20, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    tr('Mos emas'),
                    style: TextStyle(fontSize: 17, height: 22 / 17, color: fg).inter(FontWeight.w600),
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
