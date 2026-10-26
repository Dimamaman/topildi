import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../domain/entities/telegram_login.dart';
import '../cubit/telegram_wait_cubit.dart';
import '../../../../core/l10n/tr.dart';

class TelegramWaitPage extends StatelessWidget {
  const TelegramWaitPage({super.key, required this.login});

  final TelegramLogin login;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TelegramWaitCubit>()..start(login),
      child: _TelegramWaitView(login: login),
    );
  }
}

const _side = 20.0;
const _anim = Duration(milliseconds: 200);

/// Telegramda tasdiqlash: opens the bot on arrival; the person shares their
/// number there and comes back. The page checks every few seconds and at
/// once on return, then turns green and moves on.
class _TelegramWaitView extends StatefulWidget {
  const _TelegramWaitView({required this.login});

  final TelegramLogin login;

  @override
  State<_TelegramWaitView> createState() => _TelegramWaitViewState();
}

class _TelegramWaitViewState extends State<_TelegramWaitView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from Telegram: check at once instead of waiting for the next tick.
    _lifecycle = AppLifecycleListener(onResume: () => context.read<TelegramWaitCubit>().check());
    WidgetsBinding.instance.addPostFrameCallback((_) => _openBot());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _openBot() async {
    var opened = false;
    try {
      opened = await launchUrl(widget.login.url, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened && mounted) TFeedback.error(context, tr('Telegramni ochib boʻlmadi'));
  }

  Future<void> _onResult(BuildContext context, TelegramWaitState state) async {
    if (state.status != TelegramWaitStatus.verified) return;
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (context.mounted) context.go(state.needsProfile ? Routes.profileSetup : Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = math.max(34.0, MediaQuery.paddingOf(context).bottom);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocConsumer<TelegramWaitCubit, TelegramWaitState>(
        listenWhen: (a, b) => a.status != b.status,
        listener: _onResult,
        builder: (context, state) {
          final verified = state.status == TelegramWaitStatus.verified;
          final expired = state.status == TelegramWaitStatus.expired;
          final accent = verified ? tc.success : (expired ? cs.error : cs.primary);
          return Scaffold(
            body: Column(
              children: [
                SizedBox(height: top < 30 ? top + 8 : top),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _GlassBack(onTap: () => context.pop()),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(_side, 12, _side, bottom),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight - 12 - bottom),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              Center(child: _Badge(accent: accent, verified: verified, expired: expired)),
                              const SizedBox(height: 28),
                              Semantics(
                                header: true,
                                liveRegion: true,
                                child: Text(
                                  verified
                                      ? tr('Tasdiqlandi!')
                                      : expired
                                      ? tr('Muddat tugadi')
                                      : tr('Telegramda tasdiqlang'),
                                  textAlign: TextAlign.center,
                                  style: text.headlineMedium!
                                      .copyWith(fontSize: 30, height: 36 / 30, letterSpacing: -0.5)
                                      .inter(FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  expired
                                      ? tr('Tasdiqlash uchun vaqt tugadi. Qaytadan urinib koʻring.')
                                      : tr('Botda «Raqamni ulashish» tugmasini bosing, soʻng shu yerga qayting.'),
                                  textAlign: TextAlign.center,
                                  style: text.bodyLarge!
                                      .copyWith(fontSize: 16, height: 22 / 16, color: cs.secondary)
                                      .inter(FontWeight.w400),
                                ),
                              ),
                              if (state.offline) ...[const SizedBox(height: 16), const _OfflineBanner()],
                              if (!expired && !verified) ...[
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CupertinoActivityIndicator(color: cs.onSurfaceVariant),
                                    const SizedBox(width: 10),
                                    Text(
                                      tr('Tasdiqlash kutilmoqda'),
                                      style: text.bodyMedium!
                                          .copyWith(fontSize: 14, height: 20 / 14, color: cs.onSurfaceVariant)
                                          .inter(FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                              const Spacer(),
                              const SizedBox(height: 24),
                              if (expired)
                                _PrimaryButton(label: tr('Qayta urinish'), onTap: () => context.pop())
                              else
                                _PrimaryButton(
                                  label: tr('Telegramni ochish'),
                                  icon: Symbols.send_rounded,
                                  onTap: verified ? null : _openBot,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 120px disc in the accent's tint: a paper plane while waiting, a check
/// once verified, a clock when time ran out.
class _Badge extends StatelessWidget {
  const _Badge({required this.accent, required this.verified, required this.expired});

  final Color accent;
  final bool verified, expired;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: _anim,
        width: 120,
        height: 120,
        decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: AnimatedSwitcher(
          duration: _anim,
          child: Icon(
            verified
                ? Symbols.check_rounded
                : expired
                ? Symbols.timer_off_rounded
                : Symbols.send_rounded,
            key: ValueKey((verified, expired)),
            size: 52,
            fill: 1,
            color: accent,
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

/// 56px primary capsule; 0.45 opacity while disabled.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.icon, required this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: _anim,
          opacity: onTap != null ? 1 : 0.45,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20, fill: 1, color: cs.onPrimary), const SizedBox(width: 10)],
                  Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge!
                        .copyWith(fontSize: 17, height: 22 / 17, color: cs.onPrimary)
                        .inter(FontWeight.w600),
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
