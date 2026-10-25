import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/config/features.dart';
import '../core/di/injection.dart';
import '../core/view_state.dart';
import '../features/chat/domain/entities/chat.dart';
import '../features/chat/presentation/cubit/chat_list_cubit.dart';
import '../features/notifications/presentation/cubit/notifications_cubit.dart';

import '../core/widgets/t_bottom_nav.dart';
import 'routes.dart';

/// Bottom-nav shell. Branch order: Lenta, Xarita, Chatlar, Profil. The Xarita
/// branch stays registered while its tab is hidden (see [Features.map]).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    // Chat list lives at shell level so the nav badge and the Chats tab share it.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ChatListCubit>()..load()),
        BlocProvider(create: (_) => getIt<NotificationBadgeCubit>()),
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
            onAdd: () => context.push(Routes.create),
            onSelect: (branch) => shell.goBranch(branch, initialLocation: branch == shell.currentIndex),
          ),
        ),
      ),
    );
  }
}
