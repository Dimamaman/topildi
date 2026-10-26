import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/photo_source_sheet.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/create_draft.dart';
import '../cubit/create_flow_cubit.dart';
import '../../../../core/l10n/tr.dart';

/// Step 1: found/lost + photos.
class CreateTypeStep extends StatelessWidget {
  const CreateTypeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateFlowCubit>();
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;

    return BlocBuilder<CreateFlowCubit, CreateFlowState>(
      builder: (context, state) {
        final d = state.draft;
        return ListView(
          padding: const EdgeInsets.all(TSpace.screen),
          children: [
            Text(tr('Nima boʻldi?'), style: text.titleLarge!.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: TSpace.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TypeOption(
                    selected: d.isFound,
                    icon: Symbols.volunteer_activism_rounded,
                    title: tr('Topdim'),
                    subtitle: tr('Egasini topishga yordam beraman'),
                    color: tc.found,
                    container: tc.foundContainer,
                    onTap: () => cubit.setType(ListingType.found),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeOption(
                    selected: !d.isFound,
                    icon: Symbols.search_rounded,
                    title: tr('Yoʻqotdim'),
                    subtitle: tr('Buyumimni qidiryapman'),
                    color: tc.lost,
                    container: tc.lostContainer,
                    onTap: () => cubit.setType(ListingType.lost),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSpace.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(tr('Rasmlar'), style: text.titleMedium!.copyWith(fontSize: 17, fontWeight: FontWeight.w700))),
                Text('${d.photos.length} / ${CreateDraft.maxPhotos}',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: TSpace.sm),
            GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < d.photos.length; i++)
                  _PhotoTile(path: d.photos[i], tint: i, isMain: i == 0, onRemove: () => cubit.removePhoto(i)),
                if (d.photos.length < CreateDraft.maxPhotos)
                  Builder(
                    builder: (anchor) => _AddPhotoTile(
                      onTap: () async {
                        final path = await pickPhoto(context, anchor: anchor);
                        if (path != null) cubit.addPhoto(path);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TSpace.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: tc.warningContainer, borderRadius: BorderRadius.circular(TRadius.md)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Symbols.visibility_off_rounded, size: 20, color: tc.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('Rasmda karta raqami, hujjat maʼlumotlari yoki ichidagi narsalar koʻrinmasin. Ular egasini tekshirish uchun kerak.'),
                      style: TextStyle(fontSize: 13, height: 19 / 13, color: tc.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.container,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title, subtitle;
  final Color color, container;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? container : cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TRadius.md),
          side: BorderSide(color: selected ? color : cs.outlineVariant, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: container, shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(subtitle, style: TextStyle(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.path, required this.tint, required this.isMain, required this.onRemove});

  final String path;
  final int tint;
  final bool isMain;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: ts.placeholder(tint), borderRadius: BorderRadius.circular(10)),
      child: Stack(
        children: [
          Positioned.fill(
            child: PhotoPlaceholder(icon: Symbols.image_rounded, tint: tint, path: path, iconSize: 32, radius: 10),
          ),
          if (isMain)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(4)),
                child: Text(tr('Asosiy'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onPrimary)),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: Semantics(
              button: true,
              label: tr('Rasmni oʻchirish'),
              excludeSemantics: true,
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: SizedBox.square(
                  dimension: 44,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: Color(0xB30F1420), shape: BoxShape.circle),
                      child: const Icon(Symbols.close_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.add_a_photo_rounded, color: cs.primary),
            const SizedBox(height: 6),
            Text(tr('Qoʻshish'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
          ],
        ),
      ),
    );
  }
}
