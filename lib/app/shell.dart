import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/config/features.dart';
import '../core/di/injection.dart';
import '../core/push/push_service.dart';
import '../core/view_state.dart';
import '../features/chat/domain/entities/chat.dart';
import '../features/chat/presentation/cubit/chat_list_cubit.dart';
import '../features/claim/presentation/cubit/pending_claims_cubit.dart';
import '../features/notifications/presentation/cubit/notifications_cubit.dart';

import '../core/widgets/t_bottom_nav.dart';
import 'routes.dart';

/// Bottom-nav shell. Branch order: Lenta, Xarita, Chatlar, Profil. The Xarita
/// branch stays registered while its tab is hidden (see [Features.map]).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _push = getIt<PushService>();
  late final StreamSubscription<String> _opened;

  @override
  void initState() {
    super.initState();
    // Signed in from here on: register for pushes and follow tapped ones.
    _push.start();
    _opened = _push.opened.listen((route) {
      if (mounted) GoRouter.of(context).push(route);
    });
  }

  @override
  void dispose() {
    _opened.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    // Chat list lives at shell level so the nav badge and the Chats tab share
    // it; pending claims feed the Profil tab badge.
    // Not lazy: the first reader may be a pinned sliver header, which builds
    // during layout, and creating a cubit there marks the shell dirty mid-layout.
    return MultiBlocProvider(
      providers: [
        BlocProvider(lazy: false, create: (_) => getIt<ChatListCubit>()..load()),
        BlocProvider(lazy: false, create: (_) => getIt<NotificationBadgeCubit>()),
        BlocProvider(lazy: false, create: (_) => getIt<PendingClaimsCubit>()),
      ],
      child: Scaffold(
        // The glass tab bar floats over the content; pages get its height
        // as bottom padding.
        extendBody: true,
        body: shell,
        bottomNavigationBar: BlocBuilder<ChatListCubit, ViewState<List<ChatThread>>>(
          builder: (context, _) => TBottomNav(
            currentIndex: shell.currentIndex,
            unreadChats: context.read<ChatListCubit>().unread,
            pendingClaims: context.select((PendingClaimsCubit c) => c.total),
            onAdd: () => context.push(Routes.create),
            onSelect: (branch) => shell.goBranch(branch, initialLocation: branch == shell.currentIndex),
          ),
        ),
      ),
    );
  }
}
