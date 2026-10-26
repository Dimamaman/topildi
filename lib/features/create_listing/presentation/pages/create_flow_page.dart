import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_top_bar.dart';
import '../cubit/create_flow_cubit.dart';
import '../widgets/create_details_step.dart';
import '../widgets/create_header.dart';
import '../widgets/create_location_step.dart';
import '../widgets/create_type_step.dart';

/// The three create steps in one screen: the header (progress) and the
/// bottom button stay put while the steps slide in a [PageView]. Steps are
/// moved by the button (each validates first) and by back, never by a
/// swipe, so an invalid step cannot be skipped.
///
/// From Review, "Oʻzgartirish" opens a single [initialStep] with [editing]:
/// the button saves and returns.
class CreateFlowPage extends StatefulWidget {
  const CreateFlowPage({super.key, this.initialStep = 0, this.editing = false});

  final int initialStep;
  final bool editing;

  @override
  State<CreateFlowPage> createState() => _CreateFlowPageState();
}

class _CreateFlowPageState extends State<CreateFlowPage> {
  static const _count = 3;
  static const _slide = Duration(milliseconds: 320);

  late int _step = widget.initialStep;
  late final _pages = PageController(initialPage: widget.initialStep);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Widget _body(int step) => switch (step) {
    0 => const CreateTypeStep(),
    1 => const CreateDetailsStep(),
    _ => const CreateLocationStep(),
  };

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _pages.animateToPage(step, duration: _slide, curve: Curves.easeOutCubic);
  }

  void _back() => _step > 0 && !widget.editing ? _go(_step - 1) : Navigator.maybePop(context);

  /// Validates the current step, then moves on (or saves, when editing).
  void _next() {
    FocusScope.of(context).unfocus();
    final cubit = context.read<CreateFlowCubit>();
    final ok = switch (_step) {
      1 => cubit.submitDetails(),
      2 => cubit.submitLocation(),
      _ => true,
    };
    if (!ok) return;
    if (widget.editing) {
      context.pop();
    } else if (_step < _count - 1) {
      _go(_step + 1);
    } else {
      context.push(Routes.createReview);
    }
  }

  String get _label {
    if (widget.editing) return tr('Saqlash');
    return _step == _count - 1 ? tr('Koʻrib chiqish') : tr('Keyingi');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back (gesture or button) returns to the previous step first.
      canPop: _step == 0 || widget.editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: CreateHeader(
          title: _step == 2 ? tr('Qayerda va qachon?') : tr('Yangi eʼlon'),
          step: _step + 1,
          isFirst: _step == 0 && !widget.editing,
          onLeading: _back,
        ),
        body: widget.editing
            ? _body(_step)
            : PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [for (var i = 0; i < _count; i++) _KeepAlive(child: _body(i))],
              ),
        bottomNavigationBar: TBottomBar(
          horizontal: TSpace.screen,
          children: [TButton.primary(label: _label, onPressed: _next)],
        ),
      ),
    );
  }
}

/// Keeps a step's state (text fields, map) while another step is shown.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
