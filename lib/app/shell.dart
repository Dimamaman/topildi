import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../core/view_state.dart';
import '../features/chat/domain/entities/chat.dart';
import '../features/chat/presentation/cubit/chat_list_cubit.dart';
import '../features/notifications/presentation/cubit/notifications_cubit.dart';

import '../core/widgets/t_bottom_nav.dart';
import 'routes.dart';

/// Bottom-nav shell. Branch order: Lenta, Xarita, Chatlar, Profil.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _branchToNav = [0, 1, 3, 4];

  @override
  Widget build(BuildContext context) {
    // Chat list lives at shell level so the nav badge and the Chats tab share it.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ChatListCubit>()..load()),
        BlocProvider(create: (_) => getIt<NotificationBadgeCubit>()),
      ],
      child: Scaffold(
        body: shell,
        bottomNavigationBar: BlocBuilder<ChatListCubit, ViewState<List<ChatThread>>>(
          builder: (context, _) => TBottomNav(
            currentIndex: _branchToNav[shell.currentIndex],
            unreadChats: context.read<ChatListCubit>().unread,
            onAdd: () => context.push(Routes.create),
            onSelect: (navIndex) {
              final branch = _branchToNav.indexOf(navIndex);
              shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
            },
          ),
        ),
      ),
    );
  }
}
