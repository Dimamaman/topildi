import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/photo_source_sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../create_listing/presentation/widgets/create_ui.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/claim.dart';
import '../cubit/claim_cubit.dart';
import 'claim_sent_page.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/widgets/topildi_loader.dart';

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

/// "Egaligingizni tasdiqlang", big question + 3 keys: the item with a lock
/// badge, the question in large type, the answer field with hint chips,
/// an optional proof photo, one key per attempt left, and "Soʻrov yuborish".
class _ClaimView extends StatelessWidget {
  const _ClaimView({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClaimCubit>();
    final mq = MediaQuery.of(context);
    return BlocConsumer<ClaimCubit, ClaimState>(
      listenWhen: (a, b) => a.sent != b.sent,
      listener: (context, state) {
        if (!state.sent) return;
        final target = state.view;
        final listing = target is ViewLoaded<ClaimTarget> ? target.data.listing : null;
        context.pushReplacement(Routes.claimSent(listingId), extra: ClaimSentArgs(listing: listing, claim: state.sentClaim));
        // Failures are shown by the loader capsule (see _Footer).
      },
      builder: (context, state) {
        final view = state.view;
        return Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: CreateBackground()),
              Positioned.fill(
                child: switch (view) {
                  ViewLoading() || ViewEmpty() => const Center(child: CircularProgressIndicator.adaptive()),
                  ViewError(:final isOffline) => SafeArea(
                    child: isOffline
                        ? OfflineState(onRetry: () => cubit.load(listingId))
                        : ErrorState(onRetry: () => cubit.load(listingId)),
                  ),
                  ViewLoaded(:final data) => _Form(target: data, state: state),
                },
              ),
              Positioned(
                left: 16,
                top: math.max(58.0, mq.padding.top + 4),
                child: CreateGlassButton(
                  icon: Symbols.arrow_back_rounded,
                  label: tr('Orqaga'),
                  onTap: () => context.canPop() ? context.pop() : context.go(Routes.listing(listingId)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.target, required this.state});

  final ClaimTarget target;
  final ClaimState state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _answer = TextEditingController(text: widget.state.answer);
  final _focus = FocusNode();

  @override
  void dispose() {
    _answer.dispose();
    _focus.dispose();
    super.dispose();
  }

  static const _maxAnswer = 200;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final cubit = context.read<ClaimCubit>();
    final state = widget.state;
    final l = widget.target.listing;
    final target = widget.target;
    final left = target.attemptsLeft;
    // Accepted, or still waiting for an answer: nothing new to send.
    final none = left <= 0 || target.accepted || target.hasPending;
    // A "lost" listing is answered by someone who found the item: they prove
    // they hold it by naming the owner's hidden detail.
    final lost = !l.isFound;
    final error = state.answerError;
    final top = math.max(58.0, mq.padding.top + 4) + 44 + 16;

    return Stack(
      children: [
        ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(0, top, 0, 34 + 56 + 10 + 40 + 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ItemRow(listing: l, lost: lost),
                  const SizedBox(height: 22),
                  Text(
                    lost ? tr('Buyumda qanday belgi bor?') : tr('Buyumingizda qanday belgi bor?'),
                    style: TextStyle(
                      fontSize: 32,
                      height: 38 / 32,
                      letterSpacing: -0.8,
                      color: cs.onSurface,
                    ).inter(FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Only after an answer was actually turned down.
                  if (target.rejected > 0 && !target.accepted && !target.hasPending) ...[
                    _Notice(
                      text: left <= 0
                          ? tr('Javob mos kelmadi. Urinishlar tugadi')
                          : tr('Javob mos kelmadi. Yana {n} ta urinish qoldi', {'n': left}),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _AnswerField(
                    controller: _answer,
                    focus: _focus,
                    enabled: !none,
                    error: error,
                    hint: lost
                        ? tr('Masalan: brelokda qizil yulduzcha bor')
                        : tr('Masalan: ichida koʻk rangli bank kartam bor'),
                    maxLength: _maxAnswer,
                    onChanged: cubit.setAnswer,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: Builder(
                          builder: (anchor) => _Proof(
                            path: state.proofPath,
                            enabled: !none,
                            onAdd: () async {
                              final path = await pickPhoto(context, anchor: anchor, title: tr('Dalil rasm'));
                              if (path != null) cubit.setProofPhoto(path);
                            },
                            onRemove: () => cubit.setProofPhoto(null),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Spacer(),
                      _Keys(left: left, dark: dark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _Footer(
            attemptsLeft: left,
            lost: lost,
            ready: state.answer.trim().length >= 3,
            chatId: target.acceptedClaimId,
            waiting: target.hasPending,
          ),
        ),
      ],
    );
  }
}

/// 72 thumbnail with the lock badge, then label, title and "Topuvchi: …".
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.listing, required this.lost});

  final Listing listing;
  final bool lost;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = listing;
    final area = l.district.isNotEmpty ? tr(l.district) : l.areaName.split(',').first;
    return Row(
      children: [
        SizedBox.square(
          dimension: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PhotoPlaceholder(
                icon: l.category.icon,
                tint: l.tint,
                path: l.photos.isEmpty ? null : l.photos.first,
                width: 72,
                height: 72,
                iconSize: 36,
                radius: 24,
              ),
              Positioned(
                right: -12,
                bottom: -12,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 4),
                  ),
                  child: Icon(Symbols.lock_rounded, size: 16, fill: 1, color: cs.onPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (lost ? tr('Buyum sizda ekanini tasdiqlang') : tr('Egaligingizni tasdiqlang')).toUpperCase(),
                style: TextStyle(fontSize: 13, letterSpacing: 1, color: cs.primary).inter(FontWeight.w700),
              ),
              Text(
                l.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: cs.onSurface).inter(FontWeight.w600),
              ),
              Text(
                lost
                    ? tr('Egasi: {name} · {area}', {'name': l.author.displayName, 'area': area})
                    : tr('Topuvchi: {name} · {area}', {'name': l.author.displayName, 'area': area}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant).inter(FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Javob mos kelmadi…" over the field after a rejected answer.
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(Symbols.error_rounded, size: 20, fill: 1, color: cs.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 14, height: 20 / 14, color: cs.onErrorContainer).inter(FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White multi-line field, radius 26: 2px primary ring and a soft glow
/// while focused, a 1px hairline otherwise.
class _AnswerField extends StatelessWidget {
  const _AnswerField({
    required this.controller,
    required this.focus,
    required this.enabled,
    required this.error,
    required this.hint,
    required this.maxLength,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool enabled;
  final String? error, hint;
  final int maxLength;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final placeholder = dark ? const Color(0xFF6B778C) : const Color(0xFF8A94A6);
    final text = TextStyle(fontSize: 17, height: 23 / 17, color: cs.onSurface).inter(FontWeight.w400);
    return ListenableBuilder(
      listenable: focus,
      builder: (context, _) {
        final on = focus.hasFocus;
        final ring = error != null ? cs.error : (on ? cs.primary : cs.outlineVariant);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: const BoxConstraints(minHeight: 110),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: ring, width: on || error != null ? 2 : 1),
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.10),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: controller,
                focusNode: focus,
                autofocus: enabled,
                enabled: enabled,
                onChanged: onChanged,
                minLines: 3,
                maxLines: 6,
                maxLength: maxLength,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: cs.primary,
                style: text,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: text.copyWith(color: placeholder),
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                child: Text(
                  error!,
                  style: TextStyle(fontSize: 13, height: 18 / 13, color: cs.error).inter(FontWeight.w500),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "Dalil rasm · ixtiyoriy" capsule, or the attached photo with a close button.
class _Proof extends StatelessWidget {
  const _Proof({required this.path, required this.enabled, required this.onAdd, required this.onRemove});

  final String? path;
  final bool enabled;
  final VoidCallback onAdd, onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = path;
    if (p != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhotoPlaceholder(icon: Symbols.image_rounded, path: p, width: 44, height: 44, iconSize: 20, radius: 14),
          Semantics(
            button: true,
            label: tr('Dalil rasmni olib tashlash'),
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: SizedBox.square(
                dimension: 44,
                child: Icon(Symbols.close_rounded, size: 20, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: tr('Dalil rasm qoʻshish (ixtiyoriy)'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? onAdd : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            height: 44,
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
            decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.add_photo_alternate_rounded, size: 20, color: cs.onPrimaryContainer),
                const SizedBox(width: 6),
                Flexible(
                  child: Text.rich(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(
                      text: tr('Dalil rasm'),
                      children: [
                        TextSpan(
                          text: ' · ${tr('ixtiyoriy')}',
                          style: TextStyle(color: cs.onPrimaryContainer.withValues(alpha: 0.7)).inter(FontWeight.w500),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: cs.onPrimaryContainer,
                    ).inter(FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three keys, one per attempt: −12°, 0°, +12°. Used ones are grey, flat
/// and faded; the one lost last time drops into place when the page opens.
class _Keys extends StatefulWidget {
  const _Keys({required this.left, required this.dark});

  final int left;
  final bool dark;

  @override
  State<_Keys> createState() => _KeysState();
}

class _KeysState extends State<_Keys> with SingleTickerProviderStateMixin {
  late final _drop = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

  int get _used => ClaimTarget.maxAttempts - widget.left.clamp(0, ClaimTarget.maxAttempts);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_drop.isDismissed) return;
    if (_used == 0 || MediaQuery.disableAnimationsOf(context)) {
      _drop.value = 1;
      return;
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _drop.forward();
    });
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final usedColor = widget.dark ? const Color(0xFF3A4A6E) : const Color(0xFFB4BDCC);
    const tilt = [-12.0, 0.0, 12.0];
    // Keys are used up from the right.
    final firstUsed = ClaimTarget.maxAttempts - _used;
    return Semantics(
      label: tr('{n} ta urinish qoldi', {'n': widget.left.clamp(0, ClaimTarget.maxAttempts)}),
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _drop,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < ClaimTarget.maxAttempts; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              () {
                final used = i >= firstUsed;
                // The most recently used key animates; older ones are already down.
                final t = used ? (i == firstUsed ? Curves.easeIn.transform(_drop.value) : 1.0) : 0.0;
                return Transform.translate(
                  offset: Offset(0, 8 * t),
                  child: Transform.rotate(
                    angle: tilt[i] * (1 - t) * math.pi / 180,
                    child: Opacity(
                      opacity: 1 - 0.7 * t,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Color(0x140F1420), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: Icon(Symbols.key_rounded, size: 20, color: Color.lerp(cs.primary, usedColor, t)),
                      ),
                    ),
                  ),
                );
              }(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fade to the page colour, "3 ta kalit = 3 ta urinish · …" and the
/// send button (or why there is none).
class _Footer extends StatelessWidget {
  const _Footer({
    required this.attemptsLeft,
    required this.lost,
    required this.ready,
    this.chatId,
    this.waiting = false,
  });

  static Future<void> _send(BuildContext context) async {
    final cubit = context.read<ClaimCubit>();
    await TopildiLoader.run(
      context,
      task: () async {
        await cubit.submit();
        final s = cubit.state;
        return s.sent ? null : s.submitFailure;
      },
      failureOf: (f) => f,
      icon: Symbols.front_hand_rounded,
      label: tr('Soʻrov yuborilmoqda…'),
      successLabel: tr('Soʻrov yuborildi'),
      errorLabel: tr('Yuborib boʻlmadi'),
    );
  }

  final int attemptsLeft;
  final bool lost;

  /// At least 3 characters typed.
  final bool ready;

  /// The answer was accepted: open the chat instead of sending again.
  final String? chatId;

  /// A sent answer still waits for the author.
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chat = chatId;
    final none = attemptsLeft <= 0 || chat != null || waiting;
    final bottom = math.max(34.0, MediaQuery.viewPaddingOf(context).bottom);
    final String note;
    if (chat != null) {
      note = tr('Soʻrovingiz qabul qilindi. Chatda kelishib oling.');
    } else if (waiting) {
      note = tr('Soʻrovingiz hali koʻrib chiqilmoqda');
    } else if (attemptsLeft <= 0) {
      note = lost
          ? tr('Urinishlar tugadi. Egasi bilan bogʻlanib boʻlmaydi')
          : tr('Urinishlar tugadi. Topuvchi bilan bogʻlanib boʻlmaydi');
    } else {
      note = lost
          ? tr('{n} ta kalit = {n} ta urinish · Javobni faqat egasi koʻradi', {'n': attemptsLeft})
          : tr('{n} ta kalit = {n} ta urinish · Javobni faqat topuvchi koʻradi', {'n': attemptsLeft});
    }
    // Only running out of attempts is bad news.
    final bad = attemptsLeft <= 0 && chat == null && !waiting;
    // The fade only paints: taps go through to the chips under it.
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
          padding: EdgeInsets.fromLTRB(20, 40, 20, MediaQuery.viewInsetsOf(context).bottom > 0 ? 12 : bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                note,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: none ? 15 : 13,
                  height: 18 / 13,
                  color: bad ? cs.error : (none ? cs.onSurface : cs.onSurfaceVariant),
                ).inter(none ? FontWeight.w600 : FontWeight.w400),
              ),
              if (chat != null) ...[
                const SizedBox(height: 10),
                CreatePrimaryButton(
                  label: tr('Chatga oʻtish'),
                  leadingIcon: Symbols.forum_rounded,
                  onTap: () => context.push(Routes.chat(chat)),
                ),
              ],
              if (!none) ...[
                const SizedBox(height: 10),
                CreatePrimaryButton(
                  label: tr('Soʻrov yuborish'),
                  leadingIcon: Symbols.front_hand_rounded,
                  onTap: ready ? () => _send(context) : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
