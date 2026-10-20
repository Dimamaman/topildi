import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/photo_source_sheet.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../../core/widgets/t_input.dart';
import '../../../../core/widgets/t_top_bar.dart';
import '../cubit/profile_setup_cubit.dart';

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

class _ProfileSetupViewState extends State<_ProfileSetupView> {
  late final _cubit = context.read<ProfileSetupCubit>();
  late final _first = TextEditingController(text: _cubit.state.first);
  late final _last = TextEditingController(text: _cubit.state.last);

  Future<void> _changePhoto(ProfileSetupState state) async {
    if (state.hasPhoto) return _cubit.setPhoto(null);
    final path = await pickPhoto(context, title: 'Profil rasmi');
    if (path != null) _cubit.setPhoto(path);
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<ProfileSetupCubit>();

    return BlocConsumer<ProfileSetupCubit, ProfileSetupState>(
      listenWhen: (a, b) => (b.done && !a.done) || (b.failed && !a.failed),
      listener: (context, state) {
        if (state.done) {
          widget.editing && context.canPop() ? context.pop() : context.go(Routes.home);
        } else {
          TFeedback.error(context, 'Saqlab boʻlmadi. Qayta urinib koʻring');
        }
      },
      builder: (context, state) => Scaffold(
        appBar: TTopBar(
          trailing: widget.editing
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: TSpace.sm),
                  child: Text('Oxirgi qadam',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                ),
          onBack: () => context.canPop() ? context.pop() : context.go(Routes.signIn),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(TSpace.xl, TSpace.md, TSpace.xl, TSpace.xl),
          children: [
            Text(widget.editing ? 'Profilni tahrirlash' : 'Tanishib olaylik', style: text.headlineMedium),
            const SizedBox(height: TSpace.xs),
            Text('Ismingiz va rasmingiz eʼlonlarda koʻrinadi. Bu ishonchni oshiradi.',
                style: text.bodyLarge!.copyWith(color: cs.secondary)),
            const SizedBox(height: TSpace.x2l),
            Center(child: _PhotoPicker(path: state.photoPath, onTap: () => _changePhoto(state))),
            const SizedBox(height: TSpace.sm),
            Center(
              child: TextButton(
                onPressed: () => _changePhoto(state),
                child: Text(state.hasPhoto ? 'Rasmni olib tashlash' : 'Rasm qoʻshish (ixtiyoriy)'),
              ),
            ),
            const SizedBox(height: TSpace.md),
            TInput(
              label: 'Ism',
              controller: _first,
              hint: 'Ismingiz',
              autofocus: !widget.editing,
              textInputAction: TextInputAction.next,
              onChanged: cubit.setFirst,
              error: state.firstError,
              maxLength: 30,
            ),
            const SizedBox(height: 18),
            TInput(
              label: 'Familiya (ixtiyoriy)',
              controller: _last,
              hint: 'Familiyangiz',
              onChanged: cubit.setLast,
              maxLength: 30,
              helper: 'Boshqalar faqat bosh harfni koʻradi: ${state.publicName}',
            ),
          ],
        ),
        bottomNavigationBar: TBottomBar(
          horizontal: TSpace.xl,
          children: [
            TButton.primary(label: widget.editing ? 'Saqlash' : 'Tayyor', loading: state.saving, onPressed: cubit.submit),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.path, required this.onTap});

  final String? path;

  bool get hasPhoto => path != null;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: hasPhoto ? 'Rasmni olib tashlash' : 'Rasm qoʻshish',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasPhoto ? cs.primaryContainer : cs.surfaceContainerLowest,
                  border: Border.all(color: cs.outline, width: 2),
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: hasPhoto
                    ? PhotoPlaceholder(icon: Symbols.face_rounded, path: path, width: 120, height: 120, radius: 60)
                    : Icon(Symbols.person_rounded, size: 52, color: cs.onSurfaceVariant),
              ),
              Positioned(
                right: 0,
                bottom: 4,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 3),
                  ),
                  child: Icon(hasPhoto ? Symbols.edit_rounded : Symbols.photo_camera_rounded, size: 18, color: cs.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
