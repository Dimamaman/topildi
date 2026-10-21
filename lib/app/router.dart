import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../features/auth/domain/entities/phone_number.dart';
import '../features/auth/presentation/pages/profile_setup_page.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/auth/presentation/pages/sms_code_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/onboarding/presentation/pages/splash_page.dart';
import '../features/profile/presentation/pages/my_listings_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/create_listing/presentation/cubit/create_flow_cubit.dart';
import '../features/create_listing/presentation/pages/create_details_page.dart';
import '../features/create_listing/presentation/pages/create_location_page.dart';
import '../features/create_listing/presentation/pages/create_type_page.dart';
import '../features/create_listing/presentation/pages/posted_page.dart';
import '../features/create_listing/presentation/pages/review_page.dart';

import '../features/chat/presentation/pages/chat_list_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/chat/presentation/pages/success_page.dart';
import '../features/claim/presentation/pages/claim_page.dart';
import '../features/claim/presentation/pages/claim_sent_page.dart';
import '../features/claim/presentation/pages/claims_page.dart';
import '../features/listing/presentation/pages/detail_page.dart';
import '../features/listing/presentation/pages/home_page.dart';
import '../features/listing/presentation/pages/map_page.dart';
import 'coming_soon_page.dart';
import 'routes.dart';
import 'shell.dart';

GoRouter createRouter({String initialLocation = Routes.splash}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingPage()),
    GoRoute(
      path: Routes.signIn,
      builder: (_, _) => const SignInPage(),
      routes: [
        GoRoute(
          path: 'code',
          redirect: (_, state) => state.extra is PhoneNumber ? null : Routes.signIn,
          builder: (_, state) => SmsCodePage(phone: state.extra! as PhoneNumber),
        ),
      ],
    ),
    GoRoute(
      path: Routes.profileSetup,
      builder: (_, s) => ProfileSetupPage(editing: _editing(s)),
    ),
    GoRoute(
      path: Routes.terms,
      builder: (_, _) => const ComingSoonPage(title: 'Foydalanish shartlari'),
    ),
    GoRoute(
      path: Routes.privacy,
      builder: (_, _) => const ComingSoonPage(title: 'Maxfiylik siyosati'),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomePage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.map, builder: (_, _) => const MapPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.chats, builder: (_, _) => const ChatListPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfilePage())],
        ),
      ],
    ),
    // Chat opens above the shell (no bottom nav), like the design.
    GoRoute(
      path: '/chats/:id',
      builder: (_, state) => ChatPage(chatId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/success/:id',
      builder: (_, state) => SuccessPage(chatId: state.pathParameters['id']!),
    ),
    GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsPage()),
    GoRoute(path: Routes.myListings, builder: (_, _) => const MyListingsPage()),
    // Create flow shares one CreateFlowCubit across its steps.
    ShellRoute(
      builder: (_, _, child) => BlocProvider(create: (_) => getIt<CreateFlowCubit>(), child: child),
      routes: [
        GoRoute(
          path: Routes.create,
          builder: (_, s) => CreateTypePage(editing: _editing(s)),
        ),
        GoRoute(
          path: Routes.createDetails,
          builder: (_, s) => CreateDetailsPage(editing: _editing(s)),
        ),
        GoRoute(
          path: Routes.createLocation,
          builder: (_, s) => CreateLocationPage(editing: _editing(s)),
        ),
        GoRoute(path: Routes.createReview, builder: (_, _) => const ReviewPage()),
        GoRoute(path: Routes.createPosted, builder: (_, _) => const PostedPage()),
      ],
    ),
    GoRoute(
      path: '/listing/:id',
      builder: (_, state) => DetailPage(listingId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'claim',
          builder: (_, state) => ClaimPage(listingId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'sent',
              builder: (_, state) => ClaimSentPage(finderName: state.extra as String?),
            ),
          ],
        ),
        GoRoute(
          path: 'claims',
          builder: (_, state) => ClaimsPage(listingId: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);

bool _editing(GoRouterState s) => s.uri.queryParameters['edit'] == '1';
