import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/widgets/glass_sheet.dart';
import '../../../../core/widgets/t_sheet_button.dart';
import '../../../../core/widgets/topildi_loader.dart';
import '../../domain/usecases/block_user.dart';
import '../../domain/usecases/unblock_user.dart';

/// BL1: asks before blocking [name], then blocks. True once they are blocked.
Future<bool> confirmBlock(BuildContext context, {required String uid, required String name}) async {
  final blocked = await showGlassSheet<bool>(
    context,
    label: tr('Bloklash'),
    builder: (_) => _BlockSheet(uid: uid, name: name),
  );
  return blocked ?? false;
}

/// Lets [uid] write again. True once they are unblocked. No confirmation:
/// blocking them back is one tap away.
Future<bool> unblock(BuildContext context, String uid) async {
  final result = await TopildiLoader.run<Either<Failure, void>>(
    context,
    task: () => getIt<UnblockUser>()(uid),
    icon: Symbols.lock_open_rounded,
    label: tr('Blokdan chiqarilmoqda…'),
    successLabel: tr('Blokdan chiqarildi'),
    errorLabel: tr('Blokdan chiqarib boʻlmadi'),
    failureOf: (r) => r.getLeft().toNullable(),
  );
  return result != null && result.isRight();
}

class _BlockSheet extends StatelessWidget {
  const _BlockSheet({required this.uid, required this.name});

  final String uid, name;

  Future<void> _block(BuildContext context) async {
    final navigator = Navigator.of(context);
    final result = await TopildiLoader.run<Either<Failure, void>>(
      context,
      task: () => getIt<BlockUser>()((uid: uid, name: name)),
      icon: Symbols.block_rounded,
      label: tr('Bloklanmoqda…'),
      tone: LoaderTone.danger,
      successLabel: tr('Bloklandi'),
      errorLabel: tr('Bloklab boʻlmadi'),
      failureOf: (r) => r.getLeft().toNullable(),
    );
    if (result == null || result.isLeft()) return;
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget point(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, height: 20 / 15, color: cs.secondary).inter(FontWeight.w400),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: cs.errorContainer, shape: BoxShape.circle),
              child: Icon(Symbols.block_rounded, size: 32, color: cs.error),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tr('{name}ni bloklaysizmi?', {'name': name}),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, letterSpacing: -0.4, color: cs.onSurface).inter(FontWeight.w800),
          ),
          const SizedBox(height: 16),
          point(Symbols.chat_bubble_rounded, tr('U sizga yoza olmaydi va “Bu meniki” soʻrovi yubora olmaydi')),
          point(Symbols.visibility_off_rounded, tr('Uning eʼlonlari sizga koʻrinmaydi')),
          point(Symbols.notifications_off_rounded, tr('U bu haqda xabar olmaydi')),
          const SizedBox(height: 6),
          TSheetButton(
            label: tr('Bloklash'),
            icon: Symbols.block_rounded,
            tone: TSheetButtonTone.danger,
            onTap: () => _block(context),
          ),
          const SizedBox(height: 10),
          TSheetButton(
            label: tr('Bekor qilish'),
            tone: TSheetButtonTone.secondary,
            onTap: () => Navigator.of(context).maybePop(false),
          ),
        ],
      ),
    );
  }
}
