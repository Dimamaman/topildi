import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/glass_sheet.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/create_draft.dart';
import '../cubit/create_flow_cubit.dart';
import '../pages/create_flow_page.dart';
import 'create_ui.dart';
import '../../../../core/l10n/tr.dart';

/// Step 2: title, category and the hidden detail.
class CreateDetailsStep extends StatefulWidget {
  const CreateDetailsStep({super.key, required this.controller, required this.top});

  final ScrollController controller;

  /// Room above the form for the preview card.
  final double top;

  @override
  State<CreateDetailsStep> createState() => _CreateDetailsStepState();
}

class _CreateDetailsStepState extends State<CreateDetailsStep> {
  late final CreateFlowCubit _cubit = context.read<CreateFlowCubit>();
  late final _title = TextEditingController(text: _cubit.state.draft.title);
  final _titleFocus = FocusNode();
  final _titleKey = GlobalKey();
  final _categoryKey = GlobalKey();
  final _hiddenKey = GlobalKey();

  @override
  void dispose() {
    _title.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// After a refused "Keyingi": bring the first wrong field into view.
  void _revealFirstError(CreateDraft d) {
    final (key, focus) = DraftValidator.title(d) != null
        ? (_titleKey, _titleFocus)
        : DraftValidator.category(d) != null
        ? (_categoryKey, null)
        : (_hiddenKey, null);
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
    focus?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateFlowCubit, CreateFlowState>(
      listenWhen: (a, b) => a.attempt != b.attempt && b.showDetailErrors,
      listener: (_, state) => _revealFirstError(state.draft),
      builder: (context, state) {
        final d = state.draft;
        final show = state.showDetailErrors;
        final categoryError = show ? DraftValidator.category(d) : null;
        final hiddenError = show ? DraftValidator.hiddenDetail(d) : null;
        return ListView(
          controller: widget.controller,
          physics: createScrollPhysics,
          padding: EdgeInsets.fromLTRB(20, widget.top, 20, createFormBottomPadding(context)),
          children: [
            CreateField(
              key: _titleKey,
              label: tr('Sarlavha'),
              controller: _title,
              focusNode: _titleFocus,
              hint: tr('Masalan: qora hamyon'),
              maxLength: 60,
              textInputAction: TextInputAction.next,
              onChanged: _cubit.setTitle,
              error: show ? DraftValidator.title(d) : null,
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: _categoryKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CreateSectionLabel(label: tr('Kategoriya'), error: categoryError != null),
                  _CategoryChips(selected: d.category, onSelected: _cubit.setCategory),
                  if (categoryError != null) CreateError(categoryError),
                ],
              ),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: _hiddenKey,
              child: _HiddenDetailRow(
                isFound: d.isFound,
                filled: d.hiddenDetail.trim().isNotEmpty,
                error: hiddenError,
                onTap: () => editHiddenDetail(context, _cubit),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Opens the "Yashirin belgi" sheet and saves what was written (step 2, Review).
Future<void> editHiddenDetail(BuildContext context, CreateFlowCubit cubit) async {
  final d = cubit.state.draft;
  final text = await showGlassSheet<String>(
    context,
    label: tr('Yashirin belgi'),
    builder: (_) => _HiddenDetailSheet(initial: d.hiddenDetail, isFound: d.isFound),
  );
  if (text != null) cubit.setHiddenDetail(text);
}

/// Category chips in one scrolling row; the chosen one is kept in view.
class _CategoryChips extends StatefulWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final ItemCategory? selected;
  final ValueChanged<ItemCategory> onSelected;

  @override
  State<_CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<_CategoryChips> {
  final _keys = {for (final c in ItemCategory.values) c: GlobalKey()};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(animate: false));
  }

  @override
  void didUpdateWidget(_CategoryChips old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _reveal({bool animate = true}) {
    final s = widget.selected;
    final ctx = s == null ? null : _keys[s]!.currentContext;
    if (ctx == null || !ctx.mounted) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: animate ? const Duration(milliseconds: 250) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      // Runs to both screen edges, past the 20 side padding.
      child: OverflowBox(
        minWidth: MediaQuery.sizeOf(context).width,
        maxWidth: MediaQuery.sizeOf(context).width,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: ItemCategory.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final c = ItemCategory.values[i];
            return CreateChip(
              key: _keys[c],
              label: c.label,
              icon: c.icon,
              selected: c == widget.selected,
              onTap: () => widget.onSelected(c),
            );
          },
        ),
      ),
    );
  }
}

/// Capsule row like the fields: lock, "Yashirin belgi", "Kartochkada koʻrinmaydi · faqat siz
/// bilasiz" (or "✓ Qoʻshildi"), chevron. Opens the sheet; the text itself
/// is never shown here.
class _HiddenDetailRow extends StatelessWidget {
  const _HiddenDetailRow({required this.isFound, required this.filled, required this.error, required this.onTap});

  final bool isFound, filled;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final title = isFound ? tr('Yashirin belgi') : tr('Yashirin belgi · ixtiyoriy');
    final subtitle = filled ? '✓ ${tr('Qoʻshildi')}' : tr('Kartochkada koʻrinmaydi · faqat siz bilasiz');
    final err = error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: '$title, $subtitle',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: err != null ? cs.error : cs.outlineVariant,
                  width: err != null ? 2 : 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                    child: Icon(Symbols.lock_rounded, size: 20, fill: 1, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: text.titleSmall!
                              .copyWith(fontSize: 15, height: 20 / 15, color: cs.onSurface)
                              .inter(FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: text.bodySmall!
                              .copyWith(
                                fontSize: 12,
                                height: 16 / 12,
                                color: filled ? tc.success : cs.onSurfaceVariant,
                              )
                              .inter(filled ? FontWeight.w600 : FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  Icon(Symbols.chevron_right_rounded, size: 22, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        if (err != null) CreateError(err),
      ],
    );
  }
}

/// "Yashirin belgi" glass sheet, like Filtrlar: Yopish · title, why it
/// matters, the text and "Saqlash".
class _HiddenDetailSheet extends StatefulWidget {
  const _HiddenDetailSheet({required this.initial, required this.isFound});

  final String initial;
  final bool isFound;

  @override
  State<_HiddenDetailSheet> createState() => _HiddenDetailSheetState();
}

class _HiddenDetailSheetState extends State<_HiddenDetailSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  tr('Yashirin belgi'),
                  style: text.titleMedium!.copyWith(fontSize: 17, height: 22 / 17).inter(FontWeight.w600),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    button: true,
                    label: tr('Yopish'),
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox.square(
                        dimension: 44,
                        child: GlassSurface(
                          color: context.glass.control,
                          child: Icon(Symbols.close_rounded, size: 22, color: cs.onSurface),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 14, 6, 14),
          child: Text(
            widget.isFound
                ? tr('Faqat haqiqiy egasi biladigan bitta belgini yozing. Egasi shu belgini aytib, narsa oʻziniki ekanini isbotlaydi.')
                : tr('Topgan odam shu belgini aytsa, buyum haqiqatan sizniki ekanini bilasiz. Eʼlonda koʻrinmaydi.'),
            textAlign: TextAlign.center,
            style: text.bodyMedium!.copyWith(fontSize: 14, height: 20 / 14, color: cs.secondary).inter(FontWeight.w400),
          ),
        ),
        TextField(
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          style: text.bodyLarge!.copyWith(fontSize: 16, height: 22 / 16, color: cs.onSurface),
          cursorColor: cs.primary,
          decoration: InputDecoration(
            hintText: tr('Masalan: ichida koʻk rangli bank kartasi bor'),
            counterText: '',
            filled: true,
            fillColor: cs.surfaceContainerLowest,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        CreatePrimaryButton(label: tr('Saqlash'), onTap: () => Navigator.of(context).pop(_controller.text.trim())),
      ],
    );
  }
}
