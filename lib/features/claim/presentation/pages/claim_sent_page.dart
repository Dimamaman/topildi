import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/l10n/tr.dart';

/// Confirmation after a claim. The finder is notified by push; there is no
/// in-app switch to the finder side.
class ClaimSentPage extends StatelessWidget {
  const ClaimSentPage({super.key, this.finderName});

  final String? finderName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final who = finderName ?? tr('Topuvchi');

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(TSpace.xl, 56, TSpace.xl, TSpace.x2l),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 56 - TSpace.x2l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(color: tc.warningContainer, shape: BoxShape.circle),
                      child: Icon(Symbols.hourglass_top_rounded, size: 52, color: tc.warning),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(tr('Soʻrovingiz yuborildi'),
                      textAlign: TextAlign.center, style: text.headlineMedium!.copyWith(fontSize: 26, height: 34 / 26)),
                  const SizedBox(height: 18),
                  Text(
                    tr('{who} javobingizni yashirin belgi bilan solishtiradi. Natija haqida darhol xabar beramiz.', {'who': who}),
                    textAlign: TextAlign.center,
                    style: text.bodyLarge!.copyWith(color: cs.secondary),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(TSpace.md),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(TRadius.lg),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: const _Timeline(),
                  ),
                  const SizedBox(height: TSpace.x2l),
                  TButton.primary(label: tr('Lentaga qaytish'), onPressed: () => context.go(Routes.home)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _StepState { done, current, upcoming }

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Step(state: _StepState.done, title: tr('Soʻrov yuborildi'), subtitle: tr('Hozirgina')),
        _Step(state: _StepState.current, title: tr('Topuvchi tekshirmoqda'), subtitle: tr('Odatda bir necha soat')),
        _Step(state: _StepState.upcoming, title: tr('Chat ochiladi va uchrashasiz'), isLast: true),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.state, required this.title, this.subtitle, this.isLast = false});

  final _StepState state;
  final String title;
  final String? subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final dot = switch (state) {
      _StepState.done => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: tc.success, shape: BoxShape.circle),
          child: Icon(Symbols.check_rounded, size: 18, color: cs.surface, weight: 700),
        ),
      _StepState.current => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: tc.warningContainer,
            shape: BoxShape.circle,
            border: Border.all(color: tc.warning, width: 3),
          ),
        ),
      _StepState.upcoming => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cs.outlineVariant, width: 2)),
        ),
    };
    return Semantics(
      label: '$title${state == _StepState.done ? tr(', bajarildi') : state == _StepState.current ? tr(', jarayonda') : ''}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              dot,
              if (!isLast)
                Container(width: 2, height: 22, color: state == _StepState.done ? tc.success : cs.outlineVariant),
            ],
          ),
          const SizedBox(width: TSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: state == _StepState.upcoming ? cs.onSurfaceVariant : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
