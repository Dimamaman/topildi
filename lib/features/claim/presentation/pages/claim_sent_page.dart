import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/widgets/glass_header.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../create_listing/presentation/widgets/create_ui.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/claim.dart';
import '../cubit/claim_sent_cubit.dart';
import '../../../../core/theme/topildi_theme.dart';

/// What [ClaimSentPage] shows: the listing the claim is about and the claim
/// itself (followed live for the author's answer). Both are null only when
/// the page is opened without them; it then shows the plain waiting state.
class ClaimSentArgs {
  const ClaimSentArgs({this.listing, this.claim});

  final Listing? listing;
  final Claim? claim;
}

/// "Soʻrov yuborildi!", big headline (same style as "Eʼlon joylandi!"): the
/// item with a send badge, a two-line headline, a three-step timeline and
/// "Lentaga qaytish". While open it follows the claim: accepted turns into
/// "Qabul qilindi!" with "Chatga oʻtish", a rejection says how many attempts
/// are left with "Qayta urinish". ✕ and back go to the feed.
class ClaimSentPage extends StatelessWidget {
  const ClaimSentPage({super.key, this.args = const ClaimSentArgs()});

  final ClaimSentArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<ClaimSentCubit>();
        if (args.claim case final claim?) cubit.watch(claim.id);
        return cubit;
      },
      child: _ClaimSentView(args: args),
    );
  }
}

class _ClaimSentView extends StatefulWidget {
  const _ClaimSentView({required this.args});

  final ClaimSentArgs args;

  @override
  State<_ClaimSentView> createState() => _ClaimSentViewState();
}

class _ClaimSentViewState extends State<_ClaimSentView> with SingleTickerProviderStateMixin {
  /// Entry sequence (as on "Eʼlon joylandi!"): thumbnail, badge pop,
  /// headline lines 80 ms apart, then the timeline card.
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) HapticFeedback.lightImpact();
      });
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Animation<double> _interval(int fromMs, int toMs, [Curve curve = Curves.easeOut]) =>
      CurvedAnimation(parent: _intro, curve: Interval(fromMs / 700, toMs / 700, curve: curve));

  void _toFeed() => context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final listing = widget.args.listing;
    final claim = widget.args.claim;
    final lost = listing != null && !listing.isFound;
    final who = listing?.author.displayName ?? (lost ? tr('Egasi') : tr('Topuvchi'));
    final small = mq.size.height < 700;
    final headline = TextStyle(
      fontSize: small ? 36 : 44,
      height: small ? 40 / 36 : 48 / 44,
      letterSpacing: -1.6,
    ).inter(FontWeight.w800);

    return PopScope(
      canPop: false,
      // Back leaves for the feed, not the claim form (the flow is done).
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _toFeed();
      },
      child: BlocBuilder<ClaimSentCubit, ClaimStatus>(
        builder: (context, status) {
          final attemptsLeft = math.max(0, ClaimTarget.maxAttempts - (claim?.attempt ?? 1));
          final (first, second) = status == ClaimStatus.accepted
              ? (tr('Qabul'), tr('qilindi!'))
              : (tr('Soʻrov'), tr('yuborildi!'));
          final note = switch (status) {
            ClaimStatus.accepted => tr('{who} javobingizni tasdiqladi. Chatda kelishib, xavfsiz joyda uchrashing.', {
              'who': who,
            }),
            ClaimStatus.rejected when attemptsLeft > 0 => tr('Javob mos kelmadi. Yana {n} ta urinish qoldi', {
              'n': attemptsLeft,
            }),
            ClaimStatus.rejected => tr('Javob mos kelmadi. Urinishlar tugadi'),
            _ => tr('{who} javobingizni yashirin belgi bilan solishtiradi. Natija haqida darhol xabar beramiz.', {
              'who': who,
            }),
          };
          final Widget button = switch (status) {
            ClaimStatus.accepted when claim != null => CreatePrimaryButton(
              label: tr('Chatga oʻtish'),
              leadingIcon: Symbols.forum_rounded,
              // A chat has the id of the claim that opened it.
              onTap: () => context.go(Routes.chat(claim.id)),
            ),
            ClaimStatus.rejected when attemptsLeft > 0 && listing != null => CreatePrimaryButton(
              label: tr('Qayta urinish'),
              onTap: () => context.pushReplacement(Routes.claim(listing.id)),
            ),
            _ => CreatePrimaryButton(label: tr('Lentaga qaytish'), onTap: _toFeed),
          };

          return Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: CreateBackground()),
                CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: small ? math.max(72, mq.padding.top + 52) : math.max(116, mq.padding.top + 57)),
                          if (listing != null) ...[
                            Padding(
                              // Right: clear of the ✕ (44 + gap), which it can reach on small screens.
                              padding: const EdgeInsets.fromLTRB(20, 0, 72, 0),
                              child: _ItemRow(
                                listing: listing,
                                lift: _interval(0, 300),
                                pop: _interval(150, 570, const Cubic(0.3, 1.4, 0.5, 1)),
                              ),
                            ),
                            SizedBox(height: small ? 20 : 42),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Rise(
                                  animation: _interval(120, 420),
                                  child: Text(first, style: headline.copyWith(color: cs.onSurface)),
                                ),
                                _Rise(
                                  animation: _interval(200, 500),
                                  child: Text(second, style: headline.copyWith(color: cs.primary)),
                                ),
                                const SizedBox(height: 12),
                                _Rise(
                                  animation: _interval(280, 580),
                                  child: Semantics(
                                    liveRegion: status != ClaimStatus.pending,
                                    child: Text(
                                      note,
                                      style: TextStyle(fontSize: 16, height: 23 / 16, color: cs.secondary)
                                          .inter(FontWeight.w400),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: small ? 20 : 44),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _Rise(
                              animation: _interval(250, 550),
                              child: _Timeline(who: who, status: status, sentAt: claim?.createdAt),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
                          Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, math.max(34, mq.padding.bottom)),
                            child: button,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: math.max(58, mq.padding.top + 4),
                  right: 16,
                  child: GlassCircleButton(icon: Symbols.close_rounded, semantic: tr('Yopish'), onTap: _toFeed),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Fades in while rising 12 px.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => Opacity(
      opacity: animation.value.clamp(0.0, 1.0),
      child: Transform.translate(offset: Offset(0, 12 * (1 - animation.value)), child: child),
    ),
    child: child,
  );
}

/// 72 thumbnail with the send badge, the title and "Topuvchi: {ism} ·
/// {tuman}" ("Egasi" on a lost listing). The row opens the listing.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.listing, required this.lift, required this.pop});

  final Listing listing;
  final Animation<double> lift, pop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = listing;
    final area = l.district.isNotEmpty ? tr(l.district) : l.areaName.split(',').first;
    final meta = l.isFound
        ? tr('Topuvchi: {name} · {area}', {'name': l.author.displayName, 'area': area})
        : tr('Egasi: {name} · {area}', {'name': l.author.displayName, 'area': area});
    return Semantics(
      button: true,
      label: '${l.title}. $meta',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(Routes.listing(l.id)),
        child: Row(
          children: [
            _Rise(
              animation: lift,
              child: SizedBox.square(
                dimension: 72,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PhotoPlaceholder(
                      icon: l.category.icon,
                      // The listing's own colour, as in the feed and on the claim form.
                      tint: l.tint,
                      path: l.photos.isEmpty ? null : l.photos.first,
                      width: 72,
                      height: 72,
                      iconSize: 34,
                      radius: 22,
                    ),
                    // 32 disc at (−8, −8) from the corner, inside a 4 px ring.
                    Positioned(
                      right: -12,
                      bottom: -12,
                      child: AnimatedBuilder(
                        animation: pop,
                        builder: (context, child) => Transform.scale(scale: 0.4 + 0.6 * pop.value, child: child),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 4),
                          ),
                          child: Icon(Symbols.send_rounded, size: 16, fill: 1, color: cs.onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, height: 21 / 16, color: cs.onSurface).inter(FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant).inter(FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Mark { done, current, failed, active, upcoming }

/// White card: sent → {name} checking → chat opens.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.who, required this.status, this.sentAt});

  final String who;
  final ClaimStatus status;
  final DateTime? sentAt;

  String get _sentAgo {
    final since = sentAt == null ? Duration.zero : DateTime.now().difference(sentAt!);
    return since.inMinutes < 1 ? tr('Hozirgina') : tr('{n} daqiqa oldin', {'n': since.inMinutes});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accepted = status == ClaimStatus.accepted;
    final rejected = status == ClaimStatus.rejected;
    final (check, checkNote) = accepted
        ? (tr('{name} tasdiqladi', {'name': who}), tr('Javobingiz mos keldi'))
        : rejected
        ? (tr('{name} tekshirdi', {'name': who}), tr('Javobingiz mos kelmadi'))
        : (tr('{name} tekshirmoqda', {'name': who}), tr('Javobingizni yashirin belgi bilan solishtiradi'));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x0F0F1420), offset: Offset(0, 10), blurRadius: 28)],
      ),
      child: Column(
        children: [
          _Step(mark: _Mark.done, title: tr('Soʻrov yuborildi'), note: _sentAgo, index: 1, lineDone: true),
          _Step(
            mark: accepted ? _Mark.done : (rejected ? _Mark.failed : _Mark.current),
            title: check,
            note: checkNote,
            index: 2,
            lineDone: accepted,
            live: true,
          ),
          _Step(
            mark: accepted ? _Mark.active : _Mark.upcoming,
            title: tr('Chat ochiladi'),
            note: tr('Kelishib, xavfsiz joyda uchrashasiz'),
            index: 3,
          ),
        ],
      ),
    );
  }
}

/// Grey of a step not reached yet; not in the colour scheme.
class _Muted {
  const _Muted(this.ring, this.icon, this.title, this.note);

  final Color ring, icon, title, note;

  static const _light = _Muted(Color(0xFFDCE2EC), Color(0xFFB4BDCC), Color(0xFF8A94A6), Color(0xFFB4BDCC));
  static const _dark = _Muted(Color(0xFF5F6672), Color(0xFF5F6672), Color(0xFF8E95A3), Color(0xFF5F6672));

  static _Muted of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

/// One timeline step: a 30 mark, the 2 px line down to the next mark
/// (primary once passed), title and note. The last step has no line.
class _Step extends StatelessWidget {
  const _Step({
    required this.mark,
    required this.title,
    required this.note,
    required this.index,
    this.lineDone = false,
    this.live = false,
  });

  final _Mark mark;
  final String title, note;
  final int index;

  /// The line down to the next step is primary (passed); the last step has none.
  final bool lineDone;

  /// Announced when it changes (the author's answer).
  final bool live;

  bool get _last => index == 3;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = _Muted.of(context);
    final upcoming = mark == _Mark.upcoming;
    return Semantics(
      label: tr('{n}-qadam: {text}', {'n': index, 'text': title}),
      value: note,
      liveRegion: live,
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 30,
              child: Column(
                children: [
                  _MarkIcon(mark: mark),
                  if (!_last)
                    Expanded(
                      child: Container(width: 2, color: lineDone ? cs.primary : muted.ring),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: _last ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        color: upcoming ? muted.title : cs.onSurface,
                      ).inter(upcoming ? FontWeight.w600 : FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: upcoming ? muted.note : cs.onSurfaceVariant,
                      ).inter(FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkIcon extends StatelessWidget {
  const _MarkIcon({required this.mark});

  final _Mark mark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = _Muted.of(context);
    return switch (mark) {
      _Mark.done => _disc(cs.primary, Icon(Symbols.check_rounded, size: 18, weight: 700, color: cs.onPrimary)),
      _Mark.failed => _disc(cs.error, Icon(Symbols.close_rounded, size: 18, weight: 700, color: cs.onError)),
      _Mark.current => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: context.primaryGlow(0.12), spreadRadius: 5)],
        ),
        alignment: Alignment.center,
        child: _Spinner(color: cs.primary),
      ),
      _Mark.active => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(color: cs.primary, width: 2),
        ),
        child: Icon(Symbols.forum_rounded, size: 16, color: cs.primary),
      ),
      _Mark.upcoming => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: muted.ring, width: 2)),
        child: Icon(Symbols.forum_rounded, size: 16, color: muted.icon),
      ),
    };
  }

  static Widget _disc(Color color, Widget child) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: child,
  );
}

/// 16 px arc turning once a second; still with "reduce motion".
class _Spinner extends StatefulWidget {
  const _Spinner({required this.color});

  final Color color;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _turn,
    child: CustomPaint(size: const Size.square(16), painter: _ArcPainter(widget.color)),
  );
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      (Offset.zero & size).deflate(1),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
