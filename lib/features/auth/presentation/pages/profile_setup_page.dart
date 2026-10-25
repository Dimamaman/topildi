import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/media/photo_picker.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/avatar_tone.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/pull_down_menu.dart';
import '../cubit/profile_setup_cubit.dart';
import '../../../../core/widgets/photo_placeholder.dart';

const _anim = Duration(milliseconds: 200);

/// Emoji avatars offered in the 6×4 picker.
const _emojis = [
  '😊', '😎', '🤠', '🥳', '😇', '🤓', //
  '🐱', '🐶', '🦊', '🐼', '🐻', '🐨', //
  '🌸', '🌻', '🌈', '⭐', '🍀', '🔥', //
  '⚽', '🏀', '🎒', '🚲', '🎧', '📚',
];

/// "Tanishib olaylik" — last sign-up step (and Profil → edit): name and
/// an avatar picked around an "orbit": camera,
/// gallery, emoji and three colour dots.
class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key, this.editing = false});

  /// Opened from Profile: prefilled, and returns there when saved.
  final bool editing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final c = getIt<ProfileSetupCubit>();
        if (editing) c.prefill();
        return c;
      },
      child: _ProfileSetupView(editing: editing),
    );
  }
}

class _ProfileSetupView extends StatefulWidget {
  const _ProfileSetupView({required this.editing});

  final bool editing;

  @override
  State<_ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<_ProfileSetupView> with SingleTickerProviderStateMixin {
  late final _cubit = context.read<ProfileSetupCubit>();
  late final _first = TextEditingController(text: _cubit.state.first);
  final _focus = FocusNode();

  /// Orbit buttons fly out from the avatar when the screen opens.
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 470))..forward();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _first.dispose();
    _focus.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _pick(PhotoSource source) async {
    final path = await getIt<PhotoPicker>().pick(source);
    if (path != null && mounted) _cubit.setPhoto(path);
  }

  /// Once there is a photo, the camera button becomes "edit" with a menu.
  Future<void> _photoMenu(BuildContext anchor) async {
    final v = await showPullDownMenu<int>(
      context,
      anchor: anchor,
      label: tr('Profil rasmi'),
      items: [(0, tr('Suratga olish')), (1, tr('Galereyadan tanlash')), (2, tr('Rasmni olib tashlash'))],
      current: -1,
      destructive: const {2},
    );
    switch (v) {
      case 0:
        await _pick(PhotoSource.camera);
      case 1:
        await _pick(PhotoSource.gallery);
      case 2:
        _cubit.setPhoto(null);
    }
  }

  Future<void> _emojiSheet() async {
    final current = _cubit.state.emoji;
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => _EmojiSheet(current: current),
    );
    if (picked == null) return;
    _cubit.setEmoji(picked.isEmpty ? null : picked);
  }

  void _onState(BuildContext context, ProfileSetupState state) {
    if (state.done) {
      HapticFeedback.lightImpact();
      widget.editing && context.canPop() ? context.pop() : context.go(Routes.home);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom > 0;
    final top = mq.padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocConsumer<ProfileSetupCubit, ProfileSetupState>(
        listenWhen: (a, b) => (b.done && !a.done) || (b.failed && !a.failed) || (b.offline && !a.offline),
        listener: _onState,
        builder: (context, state) => Scaffold(
          body: DecoratedBox(
            // Soft blue light behind the orbit, page colour further down.
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.2,
                colors: [dark ? cs.surfaceContainerLowest : cs.primaryContainer, cs.surface],
                stops: const [0, 0.6],
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: top < 30 ? top + 8 : top),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _GlassBack(onTap: () => context.canPop() ? context.pop() : context.go(Routes.signIn)),
                      Expanded(
                        child: Center(
                          child: _StepCapsule(label: widget.editing ? tr('Profilni tahrirlash') : tr('Oxirgi qadam')),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: AbsorbPointer(
                    absorbing: state.saving,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final bottom = keyboard ? 8.0 : math.max(34.0, mq.padding.bottom);
                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(20, keyboard ? 4 : 24, 20, bottom),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(0, c.maxHeight - (keyboard ? 12 : 24) - bottom),
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(end: keyboard ? 170 : 270),
                                      duration: _anim,
                                      curve: Curves.easeOut,
                                      builder: (context, size, _) => _Orbit(
                                        size: size,
                                        intro: _intro,
                                        state: state,
                                        showDots: !keyboard,
                                        onCamera: (anchor) =>
                                            state.hasPhoto ? _photoMenu(anchor) : _pick(PhotoSource.camera),
                                        onGallery: () => _pick(PhotoSource.gallery),
                                        onEmoji: _emojiSheet,
                                        onTone: _cubit.toggleTone,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: keyboard ? 10 : 22),
                                  _NameBlock(
                                    controller: _first,
                                    focus: _focus,
                                    autofocus: !widget.editing,
                                    onChanged: _cubit.setFirst,
                                  ),
                                  AnimatedSize(
                                    duration: _anim,
                                    child: keyboard
                                        ? const SizedBox(width: double.infinity)
                                        : Padding(
                                            padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
                                            child: _Hint(publicName: state.publicName),
                                          ),
                                  ),
                                  const Spacer(),
                                  const SizedBox(height: 20),
                                  if (state.offline) ...[const _OfflineBanner(), const SizedBox(height: 12)],
                                  if (state.failed || state.firstError != null) ...[
                                    Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        state.firstError ?? tr('Saqlab boʻlmadi. Qayta urinib koʻring'),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodyMedium!
                                            .copyWith(fontSize: 14, height: 20 / 14, color: cs.error)
                                            .inter(FontWeight.w500),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  _PrimaryButton(
                                    label: widget.editing ? tr('Saqlash') : tr('Tayyor'),
                                    ready: state.canSubmit,
                                    loading: state.saving,
                                    onTap: state.canSubmit ? _cubit.submit : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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

/// The orbit: dashed outer ring, thin inner ring, the avatar in the
/// middle, three glass buttons and three colour dots on the ring.
class _Orbit extends StatelessWidget {
  const _Orbit({
    required this.size,
    required this.intro,
    required this.state,
    required this.showDots,
    required this.onCamera,
    required this.onGallery,
    required this.onEmoji,
    required this.onTone,
  });

  final double size;
  final Animation<double> intro;
  final ProfileSetupState state;
  final bool showDots;
  final void Function(BuildContext anchor) onCamera;
  final VoidCallback onGallery, onEmoji;
  final ValueChanged<int> onTone;

  /// Buttons stick out of the ring: 28 above (camera), 18 to the sides.
  static const _top = 28.0, _sideOut = 18.0, _bottomOut = 8.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final k = size / 270;
    final button = 44 + (size - 170) / 100 * 12; // 56 at full size, 44 while typing
    final center = Offset(size / 2, size / 2);
    Offset onRing(double deg) =>
        center + Offset(math.cos(deg * math.pi / 180), math.sin(deg * math.pi / 180)) * (size / 2);

    Widget place(Offset c, double extent, Widget child) => Positioned(
      left: _sideOut + c.dx - extent / 2,
      top: _top + c.dy - extent / 2,
      width: extent,
      height: extent,
      child: child,
    );

    // Each button flies from the avatar to its spot, 60ms after the previous one.
    Widget flying(int i, double deg, Widget child) => AnimatedBuilder(
      animation: intro,
      child: child,
      builder: (context, child) {
        final start = i * 60 / 470, end = (i * 60 + 350) / 470;
        final t = Curves.easeOutBack.transform(((intro.value - start) / (end - start)).clamp(0.0, 1.0));
        return place(Offset.lerp(center, onRing(deg), t)!, button, Opacity(opacity: t.clamp(0.0, 1.0), child: child));
      },
    );

    final hasImage = state.hasPhoto;
    final dots = [
      (tone: 1, deg: 218.6, d: 16.0, color: tc.foundContainer, label: tr('Yashil')),
      (tone: 2, deg: -41.0, d: 14.0, color: tc.lostContainer, label: tr('Shaftoli')),
      (tone: 3, deg: 90.0, d: 14.0, color: tc.warningContainer, label: tr('Sariq')),
    ];

    return SizedBox(
      width: size + 2 * _sideOut,
      height: size + _top + _bottomOut,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: _sideOut,
            top: _top,
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingsPainter(
                outer: dark ? const Color(0xFF3A4A6E) : cs.inversePrimary,
                inner: cs.primary.withValues(alpha: 0.18),
                inset: 40 * k,
              ),
            ),
          ),
          place(center, 150 * k, _Avatar(state: state, scale: k)),
          for (final dot in dots)
            place(
              onRing(dot.deg),
              44,
              AnimatedOpacity(
                duration: _anim,
                opacity: !showDots ? 0 : (hasImage ? 0.4 : 1),
                child: IgnorePointer(
                  ignoring: !showDots || hasImage,
                  child: Semantics(
                    button: true,
                    selected: state.tone == dot.tone,
                    label: tr('Avatar rangi: {name}', {'name': dot.label}),
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => onTone(dot.tone),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedScale(
                          duration: _anim,
                          scale: state.tone == dot.tone ? 1.3 : 1,
                          child: Container(
                            width: dot.d,
                            height: dot.d,
                            decoration: BoxDecoration(
                              color: dot.color,
                              shape: BoxShape.circle,
                              border: Border.all(color: dark ? cs.surface : cs.surfaceContainerLowest, width: 3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          flying(
            0,
            -90,
            Builder(
              builder: (anchor) => _OrbitButton(
                icon: hasImage ? Symbols.edit_rounded : Symbols.photo_camera_rounded,
                filled: !hasImage,
                label: hasImage ? tr('Profil rasmi') : tr('Suratga olish'),
                onTap: () => onCamera(anchor),
              ),
            ),
          ),
          flying(
            1,
            155,
            _OrbitButton(icon: Symbols.photo_library_rounded, label: tr('Galereyadan tanlash'), onTap: onGallery),
          ),
          flying(2, 25, _OrbitButton(icon: Symbols.mood_rounded, label: tr('Emoji tanlash'), onTap: onEmoji)),
        ],
      ),
    );
  }
}

/// Dashed outer ring (dash 4, gap 4) and a thin inner ring.
class _RingsPainter extends CustomPainter {
  const _RingsPainter({required this.outer, required this.inner, required this.inset});

  final Color outer, inner;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 0.75;
    final dash = Paint()
      ..color = outer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final count = (2 * math.pi * r / 8).floor();
    final step = 2 * math.pi / count;
    final sweep = step / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, i * step, sweep, false, dash);
    }
    canvas.drawCircle(
      c,
      size.width / 2 - inset,
      Paint()
        ..color = inner
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.outer != outer || old.inner != inner || old.inset != inset;
}

/// 150dp circle: photo, emoji, the name's first letter, or a person icon.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.state, required this.scale});

  final ProfileSetupState state;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = avatarToneColors(context, state.tone);
    final name = state.first.trim();
    final path = state.photoPath;
    final Widget content;
    final Key key;
    if (photoProvider(path) != null) {
      key = ValueKey('photo:$path');
      content = Image(image: photoProvider(path)!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (state.emoji != null) {
      key = ValueKey('emoji:${state.emoji}');
      content = Center(
        child: Text(
          state.emoji!,
          textScaler: TextScaler.noScaling,
          style: TextStyle(fontSize: 72 * scale, height: 1),
        ),
      );
    } else if (name.isNotEmpty) {
      key = const ValueKey('letter');
      content = Center(
        child: Text(
          name.characters.first.toUpperCase(),
          textScaler: TextScaler.noScaling,
          style: Theme.of(
            context,
          ).textTheme.displaySmall!.copyWith(fontSize: 64 * scale, height: 1, color: fg).inter(FontWeight.w700),
        ),
      );
    } else {
      key = const ValueKey('empty');
      content = Center(
        child: Icon(Symbols.person_rounded, size: 64 * scale, color: fg, fill: 1),
      );
    }
    return Semantics(
      image: true,
      label: tr('Profil rasmi'),
      child: AnimatedContainer(
        duration: _anim,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.45)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 40 * scale,
              offset: Offset(0, 18 * scale),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          // New photo / emoji: fade + scale 0.9 → 1.
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
          ),
          child: KeyedSubtree(key: key, child: content),
        ),
      ),
    );
  }
}

class _OrbitButton extends StatelessWidget {
  const _OrbitButton({required this.icon, required this.label, required this.onTap, this.filled = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: GlassSurface(
          color: dark ? const Color(0x1FFFFFFF) : const Color(0xD9FFFFFF),
          rim: dark ? const Color(0x40FFFFFF) : null,
          child: Center(
            child: Icon(icon, size: 24, fill: filled ? 1 : 0, color: cs.primary),
          ),
        ),
      ),
    );
  }
}

/// "Salom," + the big centred name field with its underline.
class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.controller, required this.focus, required this.autofocus, required this.onChanged});

  final TextEditingController controller;
  final FocusNode focus;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final base = text.displaySmall!.copyWith(letterSpacing: -1.2, color: cs.primary).inter(FontWeight.w800);
    return Column(
      children: [
        Text(
          tr('Salom,'),
          textAlign: TextAlign.center,
          style: text.titleLarge!
              .copyWith(fontSize: 22, height: 28 / 22, color: cs.onSurfaceVariant)
              .inter(FontWeight.w600),
        ),
        const SizedBox(height: 2),
        // Not a LayoutBuilder: the page column uses IntrinsicHeight.
        Builder(
          builder: (context) => ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, v, _) {
              // Long names shrink from 44 to 32 to stay on one line.
              final shown = v.text.isEmpty ? tr('Ismingiz') : v.text;
              final scaler = MediaQuery.textScalerOf(context);
              final painter = TextPainter(
                text: TextSpan(text: shown, style: base.copyWith(fontSize: 44)),
                textDirection: TextDirection.ltr,
                maxLines: 1,
                textScaler: scaler,
              )..layout();
              // Page side padding 20 + 20, plus a little air.
              final room = MediaQuery.sizeOf(context).width - 56;
              final size = painter.width <= room ? 44.0 : (44 * room / painter.width).clamp(32.0, 44.0);
              painter.dispose();
              return TextField(
                controller: controller,
                focusNode: focus,
                autofocus: autofocus,
                onChanged: onChanged,
                textAlign: TextAlign.center,
                maxLines: 1,
                maxLength: 30,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.givenName],
                cursorColor: cs.primary,
                cursorWidth: 3,
                cursorHeight: 42 * size / 44,
                cursorRadius: const Radius.circular(2),
                style: base.copyWith(fontSize: size, height: 48 / 44),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: tr('Ismingiz'),
                  hintStyle: base.copyWith(fontSize: size, height: 48 / 44, color: cs.outline),
                ),
              );
            },
          ),
        ),
        // The field's line box already leaves room under the text.
        AnimatedOpacity(
          duration: _anim,
          opacity: focus.hasFocus ? 1 : 0.25,
          child: Container(
            width: 220,
            height: 2,
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2)),
          ),
        ),
      ],
    );
  }
}

/// "Rasm tanlang — kamera, galereya yoki emoji. Eʼlonlaringizda **Ism** boʻlib koʻrinasiz."
class _Hint extends StatelessWidget {
  const _Hint({required this.publicName});

  final String publicName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: 14, height: 20 / 14, color: cs.onSurfaceVariant);
    final spans = <InlineSpan>[TextSpan(text: tr('Rasm tanlang — kamera, galereya yoki emoji.'))];
    if (publicName.isNotEmpty) {
      // The name is bold: split the translated sentence around it.
      final sentence = tr('Eʼlonlaringizda {name} boʻlib koʻrinasiz.', {'name': '\u0000'});
      final parts = sentence.split('\u0000');
      spans
        ..add(TextSpan(text: ' ${parts.first}'))
        ..add(
          TextSpan(
            text: publicName,
            style: base.copyWith(color: cs.onSurface).inter(FontWeight.w600),
          ),
        )
        ..add(TextSpan(text: parts.length > 1 ? parts[1] : ''));
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: TextAlign.center,
    );
  }
}

class _StepCapsule extends StatelessWidget {
  const _StepCapsule({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 32,
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelMedium!
                .copyWith(fontSize: 13, height: 18 / 13, letterSpacing: 0, color: cs.secondary)
                .inter(FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _GlassBack extends StatelessWidget {
  const _GlassBack({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tr('Orqaga'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 44,
          child: GlassSurface(
            child: Icon(Symbols.chevron_left_rounded, size: 24, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.ready, required this.loading, required this.onTap});

  final String label;
  final bool ready, loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: ready && !loading,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: _anim,
          opacity: ready || loading ? 1 : 0.45,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
            child: loading
                ? CupertinoActivityIndicator(color: cs.onPrimary)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge!
                          .copyWith(fontSize: 17, height: 22 / 17, color: cs.onPrimary)
                          .inter(FontWeight.w600),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: tc.warningContainer, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(Symbols.wifi_off_rounded, size: 20, color: tc.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('Internet yoʻq. Qayta urinib koʻring'),
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(fontSize: 14, height: 20 / 14, color: tc.warning)
                    .inter(FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small glass bottom sheet frame (emoji picker).
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, 8 + math.max(mq.viewInsets.bottom, mq.padding.bottom - 8)),
      child: GlassSurface(
        radius: 38,
        blur: 30,
        color: g.menu,
        rim: g.menuRim,
        shadowColor: g.sheetShadow,
        shadowBlur: 60,
        shadowOffset: 20,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

/// 6×4 emoji grid; pops the emoji ('' removes the current one).
class _EmojiSheet extends StatelessWidget {
  const _EmojiSheet({required this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = context.glass;
    return _SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('Emoji tanlang'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium!
                .copyWith(fontSize: 17, height: 22 / 17, color: cs.onSurface)
                .inter(FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (final e in _emojis)
                Semantics(
                  button: true,
                  selected: e == current,
                  label: e,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(e),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: e == current ? g.menuPressed : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(e, textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                ),
            ],
          ),
          if (current != null) ...[
            const SizedBox(height: 12),
            _SheetButton(
              label: tr('Olib tashlash'),
              fill: g.quiet,
              color: cs.error,
              onTap: () => Navigator.of(context).pop(''),
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.label, required this.fill, required this.color, required this.onTap});

  final String label;
  final Color fill, color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999)),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(fontSize: 17, height: 22 / 17, color: color).inter(FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
