import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/glass_header.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../create_listing/presentation/widgets/create_ui.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/chat.dart';
import '../cubit/success_cubit.dart';

/// "Buyum egasiga qaytdi!" (BQ1), big headline (same style as "Eʼlon
/// joylandi!" and "Soʻrov yuborildi!"): the item with a handshake badge,
/// confetti in the top right corner, a two-line headline, a returned-items
/// counter, then "Lentaga qaytish" and share. ✕ and back go to the feed.
class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SuccessCubit>()..load(chatId),
      child: BlocBuilder<SuccessCubit, ViewState<ReturnSummary>>(
        builder: (context, state) => switch (state) {
          ViewLoaded(:final data) => _SuccessView(summary: data),
          ViewError() => Scaffold(
            body: SafeArea(child: ErrorState(onRetry: () => context.read<SuccessCubit>().load(chatId))),
          ),
          _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
        },
      ),
    );
  }
}

class _SuccessView extends StatefulWidget {
  const _SuccessView({required this.summary});

  final ReturnSummary summary;

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView> with SingleTickerProviderStateMixin {
  /// Entry sequence (as on "Eʼlon joylandi!"): thumbnail, badge pop and
  /// confetti, headline lines 80 ms apart, then the counter card counting up.
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
    final s = widget.summary;
    final small = mq.size.height < 700;
    final rowTop = small ? math.max(72.0, mq.padding.top + 52) : math.max(116.0, mq.padding.top + 57);
    final headline = TextStyle(
      fontSize: small ? 36 : 44,
      height: small ? 40 / 36 : 48 / 44,
      letterSpacing: -1.6,
    ).inter(FontWeight.w800);
    final (first, second) = s.iAmFinder ? (tr('Buyum egasiga'), tr('qaytdi!')) : (tr('Buyumingiz'), tr('qaytdi!'));
    final note = s.iAmFinder
        ? tr('{firstName}, bugun siz birovning kunini yaxshiladingiz. Halolligingiz uchun rahmat!', {
            'firstName': s.finderName.split(' ').first,
          })
        : tr('{finderName} buyumingizni qaytardi. Unga rahmat aytishni unutmang!', {'finderName': s.finderName});

    return PopScope(
      canPop: false,
      // Back leaves for the feed, not the finished chat.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _toFeed();
      },
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: CreateBackground()),
            Positioned.fill(
              child: _Confetti(animation: _interval(100, 700, Curves.easeOutCubic), dy: rowTop - 116),
            ),
            CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: rowTop),
                      Padding(
                        // Right: clear of the ✕ (44 + gap), which it can reach on small screens.
                        padding: const EdgeInsets.fromLTRB(20, 0, 72, 0),
                        child: _ItemRow(
                          summary: s,
                          lift: _interval(0, 300),
                          pop: _interval(150, 570, const Cubic(0.3, 1.4, 0.5, 1)),
                        ),
                      ),
                      SizedBox(height: small ? 20 : 42),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Rise(
                              animation: _interval(120, 420),
                              child: _OneLine(Text(first, maxLines: 1, style: headline.copyWith(color: cs.onSurface))),
                            ),
                            _Rise(
                              animation: _interval(200, 500),
                              child: _OneLine(Text(second, maxLines: 1, style: headline.copyWith(color: cs.primary))),
                            ),
                            const SizedBox(height: 12),
                            _Rise(
                              animation: _interval(280, 580),
                              child: Text(
                                note,
                                style: TextStyle(fontSize: 16, height: 23 / 16, color: cs.secondary).inter(FontWeight.w400),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (s.iAmFinder) ...[
                        SizedBox(height: small ? 20 : 28),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _Rise(
                            animation: _interval(250, 550),
                            child: _CounterCard(count: s.returnedCount, countUp: _interval(300, 700)),
                          ),
                        ),
                        if (s.ownerNote case final ownerNote?) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _Rise(
                              animation: _interval(300, 600),
                              child: _NoteCard(name: s.owner.displayName, note: ownerNote),
                            ),
                          ),
                        ],
                      ],
                      const Spacer(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, math.max(34, mq.padding.bottom)),
                        child: Row(
                          children: [
                            Expanded(child: CreatePrimaryButton(label: tr('Lentaga qaytish'), onTap: _toFeed)),
                            const SizedBox(width: 10),
                            _ShareButton(title: s.listingTitle),
                          ],
                        ),
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
      ),
    );
  }
}

/// Keeps a headline line on one line, shrinking it on narrow screens.
class _OneLine extends StatelessWidget {
  const _OneLine(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: child);
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

/// 72 thumbnail with the handshake badge, the title and "Egasi: {ism} ·
/// {vaqt}" ("Topuvchi" for the owner; only the time when there is no name).
/// The row opens the listing.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.summary, required this.lift, required this.pop});

  final ReturnSummary summary;
  final Animation<double> lift, pop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = summary;
    final time = TDate.relative(s.returnedAt, withTimeForOld: true);
    final name = s.iAmFinder ? s.owner.displayName : s.finderName;
    final meta = name.isEmpty
        ? time
        : s.iAmFinder
        ? tr('Egasi: {name} · {time}', {'name': name, 'time': time})
        : tr('Topuvchi: {name} · {time}', {'name': name, 'time': time});
    return Semantics(
      button: true,
      label: '${s.listingTitle}. $meta',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(Routes.listing(s.listingId)),
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
                      icon: s.listingCategory.icon,
                      tint: s.listingTint,
                      path: s.listingPhoto,
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
                          child: Icon(Symbols.handshake_rounded, size: 17, color: cs.onPrimary),
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
                    s.listingTitle,
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

/// White card: a 52 tile with the number (counting up from 0) and "Siz endi
/// {n} ta buyumni egasiga qaytardingiz"; the first return shows a heart in
/// hand and "Bu sizning birinchi qaytargan buyumingiz".
class _CounterCard extends StatelessWidget {
  const _CounterCard({required this.count, required this.countUp});

  final int count;
  final Animation<double> countUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final first = count <= 1;
    final base = TextStyle(fontSize: 15, height: 21 / 15, color: cs.secondary).inter(FontWeight.w400);
    final bold = TextStyle(color: cs.onSurface).inter(FontWeight.w700);
    final sentence = first
        ? tr('Bu sizning birinchi qaytargan buyumingiz')
        : tr('Siz endi {n} ta buyumni egasiga qaytardingiz', {'n': count});
    // The bold part of the sentence, as translated.
    final highlight = first ? tr('birinchi') : tr('{n} ta buyumni', {'n': count});
    final at = sentence.indexOf(highlight);
    return Semantics(
      label: sentence,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x0F0F1420), offset: Offset(0, 10), blurRadius: 28)],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: first
                  ? Icon(Symbols.volunteer_activism_rounded, size: 26, fill: 1, color: cs.primary)
                  : AnimatedBuilder(
                      animation: countUp,
                      builder: (context, _) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${(count * countUp.value).round()}',
                          style: TextStyle(
                            fontSize: 24,
                            height: 1,
                            letterSpacing: -0.5,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? cs.onPrimaryContainer
                                : cs.primary,
                          ).inter(FontWeight.w800),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text.rich(
                at < 0
                    ? TextSpan(text: sentence)
                    : TextSpan(
                        children: [
                          TextSpan(text: sentence.substring(0, at)),
                          TextSpan(text: highlight, style: bold),
                          TextSpan(text: sentence.substring(at + highlight.length)),
                        ],
                      ),
                style: base,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The owner's thank-you written after the hand-over, under the counter.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.name, required this.note});

  final String name, note;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          Text(
            tr('{displayName} yozdi', {'displayName': name}),
            style: TextStyle(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant).inter(FontWeight.w400),
          ),
          const SizedBox(height: 4),
          Text(
            '“$note”',
            style: TextStyle(fontSize: 15, height: 22 / 15, fontStyle: FontStyle.italic, color: cs.onSurface)
                .inter(FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

/// 56 circle that opens the system share sheet.
class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.title});

  final String title;

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: title,
          text: tr('{title} egasiga qaytdi!\n\nYoʻqolgan va topilgan buyumlar — Topildi ilovasida.', {'title': title}),
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Exception {
      if (context.mounted) TFeedback.error(context, tr('Ulashib boʻlmadi'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final label = tr('Doʻstlarga ulashish');
    return Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.longPress,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () => _share(context),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(ios ? Symbols.ios_share_rounded : Symbols.share_rounded, size: 22, color: cs.primary),
          ),
        ),
      ),
    );
  }
}

/// 14 pieces around (≈335, 150) in the top right corner, anchored to the
/// right edge; they fly 8–16 px outwards into place. Decoration only.
class _Confetti extends StatelessWidget {
  const _Confetti({required this.animation, required this.dy});

  final Animation<double> animation;

  /// How far the item row sits below its 116 in the design.
  final double dy;

  /// (left, top, angle in degrees) on the 390 design; shape, colour and
  /// opacity follow the index.
  static const _pieces = [
    (370.0, 150.0, 0.0),
    (379.0, 180.0, 32.0),
    (377.0, 209.0, 51.0),
    (341.0, 243.0, 83.0),
    (321.0, 189.0, 103.0),
    (289.0, 191.0, 135.0),
    (262.0, 183.0, 154.0),
    (237.0, 140.0, 186.0),
    (294.0, 133.0, 206.0),
    (299.0, 101.0, 237.0),
    (313.0, 76.0, 257.0),
    (360.0, 61.0, 289.0),
    (355.0, 119.0, 309.0),
    (385.0, 130.0, 340.0),
  ];
  static const _sizes = [Size(10, 4), Size(7, 7), Size(5, 12)];
  static const _light = [Color(0xFF2B5FD9), Color(0xFF8DB0FF), Color(0xFFF3A77E), Color(0xFFFBD38D), Color(0xFFB9CDF7)];
  static const _dark = [Color(0xFF8DB0FF), Color(0xFFB9CDF7), Color(0xFFF3A77E), Color(0xFFFBD38D), Color(0xFF8DB0FF)];
  static const _center = Offset(335, 150);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = dark ? _dark : _light;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (final (i, (left, top, angle)) in _pieces.indexed)
                () {
                  final size = _sizes[i % 3];
                  final far = i % 4 == 3;
                  final at = Offset(left + size.width / 2, top + size.height / 2);
                  final away = at - _center;
                  final dir = away.distance == 0 ? Offset.zero : away / away.distance;
                  final back = dir * (8 + (i % 3) * 4) * (1 - animation.value);
                  return Positioned(
                    right: 390 - left - size.width + back.dx,
                    top: top + dy - back.dy,
                    child: Opacity(
                      opacity: (far ? (dark ? 0.4 : 0.5) : (dark ? 0.7 : 0.85)) * animation.value.clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: angle * math.pi / 180,
                        child: Container(
                          width: size.width,
                          height: size.height,
                          decoration: BoxDecoration(
                            color: colors[i % 5],
                            borderRadius: BorderRadius.circular(size.width == size.height ? 999 : 2),
                          ),
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        ),
      ),
    );
  }
}
