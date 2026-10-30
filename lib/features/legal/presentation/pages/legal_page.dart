import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/language_cubit.dart';
import '../../../../core/links/link_launcher.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/widgets/glass_header.dart';
import '../../domain/legal_documents.dart';

const _side = GlassHeader.side;

/// Foydalanish shartlari / Maxfiylik siyosati: glass back button, a large
/// title that collapses into the bar, and each section in a white inset
/// group. Ends with a link to the other document.
class LegalPage extends StatefulWidget {
  const LegalPage({super.key, required this.kind});

  final LegalKind kind;

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  final _offset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final language = context.watch<LanguageCubit>().state;
    final doc = legalDocument(widget.kind, language);
    final top = GlassHeader.top(context);
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final other = widget.kind == LegalKind.terms
        ? (tr('Maxfiylik siyosati'), Routes.privacy, Symbols.privacy_tip_rounded)
        : (tr('Foydalanish shartlari'), Routes.terms, Symbols.description_rounded);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.depth == 0 && n.metrics.axis == Axis.vertical) _offset.value = n.metrics.pixels;
            return false;
          },
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _Bar(top: top, offset: _offset, title: doc.title),
              ),
              SliverToBoxAdapter(child: GlassLargeTitle(doc.title)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(_side, 0, _side, bottom),
                sliver: SliverList.list(
                  children: [
                    _Intro(updated: doc.updated, text: doc.intro),
                    for (final s in doc.sections) _Section(s),
                    const SizedBox(height: 22),
                    _OtherDoc(
                      label: other.$1,
                      icon: other.$3,
                      onTap: () => context.pushReplacement(other.$2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinned glass bar: back button and the inline title.
class _Bar extends SliverPersistentHeaderDelegate {
  const _Bar({required this.top, required this.offset, required this.title});

  final double top;
  final ValueListenable<double> offset;
  final String title;

  @override
  double get minExtent => top + GlassHeader.barHeight;

  @override
  double get maxExtent => top + GlassHeader.barHeight;

  @override
  bool shouldRebuild(covariant _Bar old) => old.top != top || old.offset != offset || old.title != title;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GlassBarBackground(
      offset: offset,
      hairlineAt: GlassHeader.titleExtent - 1,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: Padding(
          padding: EdgeInsets.fromLTRB(_side, top, _side, 8),
          child: Row(
            children: [
              GlassCircleButton(
                icon: Symbols.chevron_left_rounded,
                iconSize: 24,
                semantic: tr('Orqaga'),
                onTap: () => context.canPop() ? context.pop() : context.go(Routes.signIn),
              ),
              const SizedBox(width: 8),
              Expanded(child: GlassInlineTitle(title, offset: offset)),
              // Balances the back button so the title stays centred.
              const SizedBox(width: 8 + 44),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _body(BuildContext context) => Theme.of(context).textTheme.bodyLarge!
    .copyWith(fontSize: 15, height: 22 / 15, color: Theme.of(context).colorScheme.onSurface)
    .inter(FontWeight.w400);

class _Intro extends StatelessWidget {
  const _Intro({required this.updated, required this.text});

  final String updated, text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            updated,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          _Paragraph(text, style: _body(context)),
        ],
      ),
    );
  }
}

/// Heading above a white inset group (radius 26) of paragraphs and bullets.
class _Section extends StatelessWidget {
  const _Section(this.section);

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final body = _body(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
          child: Semantics(
            header: true,
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 17, height: 22 / 17).inter(FontWeight.w600),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(26)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < section.body.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                  child: section.body[i].startsWith('• ')
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 18,
                              child: Text('•', style: body.copyWith(color: cs.primary).inter(FontWeight.w700)),
                            ),
                            Expanded(child: _Paragraph(section.body[i].substring(2), style: body)),
                          ],
                        )
                      : _Paragraph(section.body[i], style: body),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paragraph in which [legalTelegram] is a link that opens the chat in Telegram.
class _Paragraph extends StatefulWidget {
  const _Paragraph(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_Paragraph> createState() => _ParagraphState();
}

class _ParagraphState extends State<_Paragraph> {
  late final _telegram = TapGestureRecognizer()
    ..onTap = () => getIt<LinkLauncher>().open(Uri.https('t.me', '/${legalTelegram.substring(1)}'));

  @override
  void dispose() {
    _telegram.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parts = widget.text.split(legalTelegram);
    if (parts.length == 1) return Text(widget.text, style: widget.style);
    final link = widget.style.copyWith(color: Theme.of(context).colorScheme.primary).inter(FontWeight.w600);
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) TextSpan(text: legalTelegram, style: link, recognizer: _telegram),
            TextSpan(text: parts[i]),
          ],
        ],
      ),
    );
  }
}

/// Row that opens the other document, in place of this one.
class _OtherDoc extends StatelessWidget {
  const _OtherDoc({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(26)),
          child: Row(
            children: [
              Icon(icon, size: 22, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16, height: 22 / 16).inter(FontWeight.w400),
                ),
              ),
              Icon(Symbols.chevron_right_rounded, size: 22, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
