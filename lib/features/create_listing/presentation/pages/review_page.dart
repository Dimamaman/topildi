import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/listing_card.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../../core/widgets/t_top_bar.dart';
import '../../../listing/presentation/category_ui.dart';
import '../cubit/create_flow_cubit.dart';
import '../widgets/create_header.dart';
import '../../../../core/l10n/tr.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool _showSecret = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<CreateFlowCubit>();

    return BlocConsumer<CreateFlowCubit, CreateFlowState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == SubmitStatus.success) context.go(Routes.createPosted);
        if (state.status == SubmitStatus.failure) {
          TFeedback.error(
            context,
            state.failure is NetworkFailure ? tr('Internet yoʻq. Qayta urinib koʻring') : tr('Eʼlonni joylab boʻlmadi'),
            action: tr('Qayta'),
            onAction: cubit.publish,
          );
        }
      },
      builder: (context, state) {
        final d = state.draft;
        final happened = d.happenedAt(DateTime.now());
        final area = d.areaName ?? '';
        final photos = d.photos.isEmpty ? 'rasmsiz' : tr('{n} ta rasm', {'n': d.photos.length});
        final rows = [
          (tr('Tur va rasmlar'), '${d.isFound ? tr('Topdim') : tr('Yoʻqotdim')} · $photos', Routes.create),
          (tr('Sarlavha va tavsif'), d.description.trim().isEmpty ? d.title : '${d.title}. ${d.description}', Routes.createDetails),
          (tr('Joy va sana'), '${area.split(',').first} · ${TDate.full(happened)}', Routes.createLocation),
        ];
        final hasSecret = d.hiddenDetail.trim().isNotEmpty;

        return Scaffold(
          appBar: CreateHeader(title: tr('Koʻrib chiqish')),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: TSpace.screen, vertical: TSpace.md),
            children: [
              Text(tr('Boshqalar shunday koʻradi'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
              const SizedBox(height: 14),
              ListingCard(
                title: d.title,
                category: d.category?.label ?? '',
                meta: '${area.split(',').first} · ${TDate.relative(happened)}',
                isFound: d.isFound,
                icon: d.category?.icon ?? Symbols.category_rounded,
                imagePath: d.photos.isEmpty ? null : d.photos.first,
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(TRadius.md),
                  border: Border.all(color: cs.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final r in rows)
                      _Row(
                        label: r.$1,
                        value: r.$2,
                        trailing: TextButton(
                          onPressed: () => context.push('${r.$3}?edit=1'),
                          child: Text(tr('Oʻzgartirish')),
                        ),
                      ),
                    if (hasSecret)
                      Container(
                        color: context.ts.primaryTint,
                        padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                        child: Row(
                          children: [
                            Icon(Symbols.lock_rounded, size: 20, color: cs.onPrimaryContainer),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('Yashirin belgi · faqat siz'),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _showSecret ? d.hiddenDetail : '•' * 18,
                                    style: const TextStyle(fontSize: 15, height: 21 / 15),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: _showSecret ? tr('Yashirish') : tr('Koʻrsatish'),
                              color: cs.primary,
                              icon: Icon(_showSecret ? Symbols.visibility_off_rounded : Symbols.visibility_rounded),
                              onPressed: () => setState(() => _showSecret = !_showSecret),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => cubit.setAgreed(!state.agreed),
                borderRadius: BorderRadius.circular(TRadius.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(value: state.agreed, onChanged: (v) => cubit.setAgreed(v ?? false)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          d.isFound
                              ? tr('Buyumni egasiga bepul qaytaraman va eʼlon qoidalariga roziman.')
                              : tr('Maʼlumotlar toʻgʻri ekanini tasdiqlayman va eʼlon qoidalariga roziman.'),
                          style: TextStyle(fontSize: 14, height: 20 / 14, color: cs.secondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: TBottomBar(
            horizontal: TSpace.screen,
            children: [
              TButton.primary(
                label: tr('Eʼlon qilish'),
                loading: state.status == SubmitStatus.submitting,
                onPressed: state.agreed ? cubit.publish : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.trailing});

  final String label, value;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 21 / 15)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
