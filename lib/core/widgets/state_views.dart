import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/topildi_surfaces.dart';
import '../theme/topildi_theme.dart';
import 'listing_card.dart';
import 't_button.dart';

/// Illustration + title + body + CTA used for empty / error / offline.
class MessageState extends StatelessWidget {
  const MessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.cta,
    this.onCta,
    required this.circle,
    required this.fg,
  });

  final IconData icon;
  final String title, body;
  final String? cta;
  final VoidCallback? onCta;
  final Color circle, fg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TSpace.x2l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 52, color: fg, weight: 300),
                  ),
                  Positioned(
                    right: 6,
                    top: 12,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: fg.withValues(alpha: 0.5), shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(title, textAlign: TextAlign.center, style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: text.bodyLarge!.copyWith(fontSize: 15, height: 22 / 15, color: cs.secondary),
              ),
            ),
            if (cta != null) ...[
              const SizedBox(height: 22),
              TButton.primary(label: cta!, onPressed: onCta, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.cta, this.onCta});

  final IconData icon;
  final String title, body;
  final String? cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MessageState(
      icon: icon,
      title: title,
      body: body,
      cta: cta,
      onCta: onCta,
      circle: cs.primaryContainer,
      fg: cs.onPrimaryContainer,
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MessageState(
      icon: Symbols.error_rounded,
      title: 'Nimadir xato ketdi',
      body: 'Maʼlumotlarni yuklab boʻlmadi. Birozdan soʻng qayta urinib koʻring.',
      cta: 'Qayta urinish',
      onCta: onRetry,
      circle: cs.errorContainer,
      fg: cs.error,
    );
  }
}

class OfflineState extends StatelessWidget {
  const OfflineState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return MessageState(
      icon: Symbols.wifi_off_rounded,
      title: 'Internet yoʻq',
      body: 'Ulanishni tekshiring. Internet qaytgach, hammasi oʻzi yangilanadi.',
      cta: 'Qayta urinish',
      onCta: onRetry,
      circle: tc.warningContainer,
      fg: tc.warning,
    );
  }
}

/// Warning strip shown above cached content while offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: TSpace.screen, vertical: 10),
        color: tc.warningContainer,
        child: Row(
          children: [
            Icon(Symbols.wifi_off_rounded, size: 18, color: tc.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Oflayn rejim: oxirgi saqlangan maʼlumotlar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tc.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton list of listing cards.
class CardsSkeleton extends StatelessWidget {
  const CardsSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Yuklanmoqda',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: TSpace.screen, vertical: TSpace.md),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const ListingCardSkeleton(),
      ),
    );
  }
}

/// Skeleton rows (avatar + two lines) for chats / notifications.
class RowsSkeleton extends StatelessWidget {
  const RowsSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final cs = Theme.of(context).colorScheme;
    Widget bar(double factor, double h, Color c) => FractionallySizedBox(
          widthFactor: factor,
          alignment: Alignment.centerLeft,
          child: Container(height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(TRadius.xs))),
        );
    return Semantics(
      label: 'Yuklanmoqda',
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: TSpace.screen, vertical: 14),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))),
          child: Row(
            children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: ts.skeleton, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bar(0.5, 14, ts.skeleton), const SizedBox(height: 8), bar(0.85, 12, ts.skeletonSoft)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
