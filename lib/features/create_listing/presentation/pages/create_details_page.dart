import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/pull_down_menu.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_input.dart';
import '../../../../core/widgets/t_top_bar.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/create_draft.dart';
import '../cubit/create_flow_cubit.dart';
import '../widgets/create_header.dart';
import '../../../../core/l10n/tr.dart';

/// Step 2: title, category, description and the hidden detail.
class CreateDetailsPage extends StatefulWidget {
  const CreateDetailsPage({super.key, this.editing = false});

  final bool editing;

  @override
  State<CreateDetailsPage> createState() => _CreateDetailsPageState();
}

class _CreateDetailsPageState extends State<CreateDetailsPage> {
  late final CreateFlowCubit _cubit = context.read<CreateFlowCubit>();
  late final _title = TextEditingController(text: _cubit.state.draft.title);
  late final _description = TextEditingController(text: _cubit.state.draft.description);
  late final _hidden = TextEditingController(text: _cubit.state.draft.hiddenDetail);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _hidden.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_cubit.submitDetails()) return;
    widget.editing ? context.pop() : context.push(Routes.createLocation);
  }

  Future<void> _pickCategory(BuildContext anchor) async {
    const all = ItemCategory.values;
    final picked = await showPullDownMenu(
      context,
      anchor: anchor,
      label: tr('Kategoriya'),
      items: [for (final c in all) (c, c.label)],
      icons: {for (var i = 0; i < all.length; i++) i: all[i].icon},
      current: _cubit.state.draft.category,
    );
    if (picked != null) _cubit.setCategory(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: CreateHeader(title: tr('Yangi eʼlon'), step: 2),
      body: BlocBuilder<CreateFlowCubit, CreateFlowState>(
        builder: (context, state) {
          final d = state.draft;
          final show = state.showDetailErrors;
          final categoryError = show ? DraftValidator.category(d) : null;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: TSpace.screen, vertical: 18),
            children: [
              TInput(
                label: tr('Sarlavha'),
                controller: _title,
                hint: tr('Masalan: qora hamyon'),
                maxLength: 60,
                textInputAction: TextInputAction.next,
                onChanged: _cubit.setTitle,
                error: show ? DraftValidator.title(d) : null,
              ),
              const SizedBox(height: TSpace.md),
              Text(tr('Kategoriya'), style: text.labelLarge!.copyWith(color: categoryError != null ? cs.error : null)),
              const SizedBox(height: 6),
              Builder(
                builder: (anchor) => Material(
                  color: cs.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TRadius.md),
                    side: BorderSide(color: categoryError != null ? cs.error : cs.outline, width: categoryError != null ? 2 : 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _pickCategory(anchor),
                    child: SizedBox(
                      height: TSize.input,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 12),
                        child: Row(
                          children: [
                            Icon(d.category?.icon ?? Symbols.category_rounded, size: 20, color: cs.onSurfaceVariant),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                d.category?.label ?? tr('Tanlang'),
                                style: text.bodyLarge!.copyWith(color: d.category == null ? cs.onSurfaceVariant : null),
                              ),
                            ),
                            Icon(Symbols.expand_more_rounded, color: cs.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (categoryError != null) ...[
                const SizedBox(height: 6),
                Text(categoryError, style: TextStyle(fontSize: 13, color: cs.error)),
              ],
              const SizedBox(height: TSpace.md),
              TInput(
                label: tr('Tavsif'),
                controller: _description,
                hint: tr('Qayerda, qanday holatda topdingiz yoki yoʻqotdingiz?'),
                maxLines: 4,
                minLines: 3,
                maxLength: CreateDraft.maxDescription,
                keyboardType: TextInputType.multiline,
                onChanged: _cubit.setDescription,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.description.length} / ${CreateDraft.maxDescription}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: TSpace.sm),
              _HiddenDetailBlock(
                controller: _hidden,
                isFound: d.isFound,
                onChanged: _cubit.setHiddenDetail,
                error: show ? DraftValidator.hiddenDetail(d) : null,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: TBottomBar(
        horizontal: TSpace.screen,
        children: [TButton.primary(label: widget.editing ? tr('Saqlash') : tr('Keyingi'), onPressed: _next)],
      ),
    );
  }
}

/// Emphasised private field: only the listing author ever sees this text.
class _HiddenDetailBlock extends StatelessWidget {
  const _HiddenDetailBlock({required this.controller, required this.isFound, required this.onChanged, this.error});

  final TextEditingController controller;
  final bool isFound;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasError = error != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.ts.primaryTint,
        borderRadius: BorderRadius.circular(TRadius.lg),
        border: Border.all(color: hasError ? cs.error : cs.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                child: Icon(Symbols.lock_rounded, size: 20, color: cs.onPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isFound ? tr('Yashirin belgi') : tr('Yashirin belgi (ixtiyoriy)'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 1),
                    Text(tr('Buni faqat siz koʻrasiz'),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 3,
            maxLines: 4,
            maxLength: 200,
            style: const TextStyle(fontSize: 15, height: 21 / 15),
            decoration: InputDecoration(
              hintText: tr('Masalan: ichida koʻk rangli bank kartasi bor'),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outline)),
              enabledBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outline)),
              focusedBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error ??
                (isFound
                    ? tr('Egasi buyumni olish uchun shu belgini oʻzi aytishi kerak. Eʼlonda koʻrinmaydi: rangi, ichidagi narsa, yozuv yoki shikast haqida yozing.')
                    : tr('Topgan odam shu belgini aytsa, buyum haqiqatan sizniki ekanini bilasiz. Eʼlonda koʻrinmaydi.')),
            style: TextStyle(fontSize: 13, height: 19 / 13, color: hasError ? cs.error : cs.secondary),
          ),
        ],
      ),
    );
  }
}
