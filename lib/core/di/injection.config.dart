// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:topildi/core/network/network_info.dart' as _i263;
import 'package:topildi/core/session/session.dart' as _i554;
import 'package:topildi/core/theme/theme_cubit.dart' as _i271;
import 'package:topildi/features/auth/data/repositories/auth_repository_impl.dart'
    as _i597;
import 'package:topildi/features/auth/domain/repositories/auth_repository.dart'
    as _i679;
import 'package:topildi/features/auth/domain/usecases/request_sms_code.dart'
    as _i190;
import 'package:topildi/features/auth/domain/usecases/save_profile.dart'
    as _i189;
import 'package:topildi/features/auth/domain/usecases/sign_in_with_google.dart'
    as _i1010;
import 'package:topildi/features/auth/domain/usecases/verify_sms_code.dart'
    as _i531;
import 'package:topildi/features/auth/presentation/cubit/profile_setup_cubit.dart'
    as _i570;
import 'package:topildi/features/auth/presentation/cubit/sign_in_cubit.dart'
    as _i480;
import 'package:topildi/features/auth/presentation/cubit/sms_code_cubit.dart'
    as _i684;
import 'package:topildi/features/chat/data/datasources/chat_mock_datasource.dart'
    as _i584;
import 'package:topildi/features/chat/data/repositories/chat_repository_impl.dart'
    as _i279;
import 'package:topildi/features/chat/domain/repositories/chat_repository.dart'
    as _i956;
import 'package:topildi/features/chat/domain/usecases/get_chat_thread.dart'
    as _i468;
import 'package:topildi/features/chat/domain/usecases/get_chats.dart' as _i141;
import 'package:topildi/features/chat/domain/usecases/get_messages.dart'
    as _i191;
import 'package:topildi/features/chat/domain/usecases/get_return_summary.dart'
    as _i581;
import 'package:topildi/features/chat/domain/usecases/mark_returned.dart'
    as _i905;
import 'package:topildi/features/chat/domain/usecases/send_message.dart'
    as _i496;
import 'package:topildi/features/chat/domain/usecases/watch_chats.dart'
    as _i956;
import 'package:topildi/features/chat/presentation/cubit/chat_cubit.dart'
    as _i358;
import 'package:topildi/features/chat/presentation/cubit/chat_list_cubit.dart'
    as _i389;
import 'package:topildi/features/chat/presentation/cubit/success_cubit.dart'
    as _i80;
import 'package:topildi/features/claim/data/datasources/claim_mock_datasource.dart'
    as _i283;
import 'package:topildi/features/claim/data/repositories/claim_repository_impl.dart'
    as _i763;
import 'package:topildi/features/claim/domain/repositories/claim_repository.dart'
    as _i28;
import 'package:topildi/features/claim/domain/usecases/accept_claim.dart'
    as _i546;
import 'package:topildi/features/claim/domain/usecases/get_claim_review.dart'
    as _i445;
import 'package:topildi/features/claim/domain/usecases/get_claim_target.dart'
    as _i164;
import 'package:topildi/features/claim/domain/usecases/reject_claim.dart'
    as _i695;
import 'package:topildi/features/claim/domain/usecases/submit_claim.dart'
    as _i774;
import 'package:topildi/features/claim/presentation/cubit/claim_cubit.dart'
    as _i176;
import 'package:topildi/features/claim/presentation/cubit/claims_cubit.dart'
    as _i573;
import 'package:topildi/features/create_listing/data/repositories/create_listing_repository_impl.dart'
    as _i434;
import 'package:topildi/features/create_listing/domain/repositories/create_listing_repository.dart'
    as _i762;
import 'package:topildi/features/create_listing/domain/usecases/post_listing.dart'
    as _i113;
import 'package:topildi/features/create_listing/presentation/cubit/create_flow_cubit.dart'
    as _i64;
import 'package:topildi/features/listing/data/datasources/listing_mock_datasource.dart'
    as _i904;
import 'package:topildi/features/listing/data/repositories/listing_repository_impl.dart'
    as _i786;
import 'package:topildi/features/listing/domain/repositories/listing_repository.dart'
    as _i856;
import 'package:topildi/features/listing/domain/usecases/get_listing_detail.dart'
    as _i445;
import 'package:topildi/features/listing/domain/usecases/get_listings.dart'
    as _i1022;
import 'package:topildi/features/listing/domain/usecases/get_map_listings.dart'
    as _i619;
import 'package:topildi/features/listing/domain/usecases/watch_listings.dart'
    as _i592;
import 'package:topildi/features/listing/presentation/cubit/detail_cubit.dart'
    as _i64;
import 'package:topildi/features/listing/presentation/cubit/feed_cubit.dart'
    as _i516;
import 'package:topildi/features/listing/presentation/cubit/filters_cubit.dart'
    as _i534;
import 'package:topildi/features/listing/presentation/cubit/map_cubit.dart'
    as _i446;
import 'package:topildi/features/notifications/data/datasources/notification_mock_datasource.dart'
    as _i669;
import 'package:topildi/features/notifications/data/repositories/notification_repository_impl.dart'
    as _i985;
import 'package:topildi/features/notifications/domain/repositories/notification_repository.dart'
    as _i1040;
import 'package:topildi/features/notifications/domain/usecases/notification_usecases.dart'
    as _i582;
import 'package:topildi/features/notifications/presentation/cubit/notifications_cubit.dart'
    as _i567;
import 'package:topildi/features/profile/data/repositories/profile_repository_impl.dart'
    as _i708;
import 'package:topildi/features/profile/domain/repositories/profile_repository.dart'
    as _i749;
import 'package:topildi/features/profile/domain/usecases/profile_usecases.dart'
    as _i126;
import 'package:topildi/features/profile/presentation/cubit/profile_cubit.dart'
    as _i533;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i554.Session>(() => _i554.Session());
    gh.lazySingleton<_i271.ThemeCubit>(() => _i271.ThemeCubit());
    gh.lazySingleton<_i584.ChatMockDataSource>(
      () => _i584.ChatMockDataSource(),
    );
    gh.lazySingleton<_i283.ClaimMockDataSource>(
      () => _i283.ClaimMockDataSource(),
    );
    gh.lazySingleton<_i904.ListingMockDataSource>(
      () => _i904.ListingMockDataSource(),
    );
    gh.lazySingleton<_i669.NotificationMockDataSource>(
      () => _i669.NotificationMockDataSource(),
    );
    gh.lazySingleton<_i263.NetworkInfo>(() => _i263.AlwaysOnlineNetworkInfo());
    gh.lazySingleton<_i1040.NotificationRepository>(
      () => _i985.NotificationRepositoryImpl(
        gh<_i669.NotificationMockDataSource>(),
        gh<_i263.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i856.ListingRepository>(
      () => _i786.ListingRepositoryImpl(
        gh<_i904.ListingMockDataSource>(),
        gh<_i263.NetworkInfo>(),
      ),
    );
    gh.factory<_i445.GetListingDetail>(
      () => _i445.GetListingDetail(gh<_i856.ListingRepository>()),
    );
    gh.factory<_i1022.GetListings>(
      () => _i1022.GetListings(gh<_i856.ListingRepository>()),
    );
    gh.factory<_i619.GetMapListings>(
      () => _i619.GetMapListings(gh<_i856.ListingRepository>()),
    );
    gh.factory<_i592.WatchListings>(
      () => _i592.WatchListings(gh<_i856.ListingRepository>()),
    );
    gh.factory<_i446.MapCubit>(
      () =>
          _i446.MapCubit(gh<_i619.GetMapListings>(), gh<_i592.WatchListings>()),
    );
    gh.factory<_i534.FiltersCubit>(
      () => _i534.FiltersCubit(gh<_i1022.GetListings>()),
    );
    gh.lazySingleton<_i28.ClaimRepository>(
      () => _i763.ClaimRepositoryImpl(
        gh<_i283.ClaimMockDataSource>(),
        gh<_i904.ListingMockDataSource>(),
        gh<_i584.ChatMockDataSource>(),
        gh<_i263.NetworkInfo>(),
        gh<_i554.Session>(),
      ),
    );
    gh.factory<_i546.AcceptClaim>(
      () => _i546.AcceptClaim(gh<_i28.ClaimRepository>()),
    );
    gh.factory<_i445.GetClaimReview>(
      () => _i445.GetClaimReview(gh<_i28.ClaimRepository>()),
    );
    gh.factory<_i164.GetClaimTarget>(
      () => _i164.GetClaimTarget(gh<_i28.ClaimRepository>()),
    );
    gh.factory<_i695.RejectClaim>(
      () => _i695.RejectClaim(gh<_i28.ClaimRepository>()),
    );
    gh.factory<_i774.SubmitClaim>(
      () => _i774.SubmitClaim(gh<_i28.ClaimRepository>()),
    );
    gh.lazySingleton<_i749.ProfileRepository>(
      () => _i708.ProfileRepositoryImpl(
        gh<_i904.ListingMockDataSource>(),
        gh<_i283.ClaimMockDataSource>(),
        gh<_i554.Session>(),
        gh<_i263.NetworkInfo>(),
      ),
    );
    gh.factory<_i516.FeedCubit>(
      () =>
          _i516.FeedCubit(gh<_i1022.GetListings>(), gh<_i592.WatchListings>()),
    );
    gh.lazySingleton<_i762.CreateListingRepository>(
      () => _i434.CreateListingRepositoryImpl(
        gh<_i904.ListingMockDataSource>(),
        gh<_i263.NetworkInfo>(),
        gh<_i554.Session>(),
      ),
    );
    gh.factory<_i582.GetNotifications>(
      () => _i582.GetNotifications(gh<_i1040.NotificationRepository>()),
    );
    gh.factory<_i582.MarkAllNotificationsRead>(
      () => _i582.MarkAllNotificationsRead(gh<_i1040.NotificationRepository>()),
    );
    gh.factory<_i582.MarkNotificationRead>(
      () => _i582.MarkNotificationRead(gh<_i1040.NotificationRepository>()),
    );
    gh.factory<_i582.WatchUnreadNotifications>(
      () => _i582.WatchUnreadNotifications(gh<_i1040.NotificationRepository>()),
    );
    gh.lazySingleton<_i679.AuthRepository>(
      () => _i597.AuthRepositoryImpl(
        gh<_i554.Session>(),
        gh<_i263.NetworkInfo>(),
      ),
    );
    gh.factory<_i190.RequestSmsCode>(
      () => _i190.RequestSmsCode(gh<_i679.AuthRepository>()),
    );
    gh.factory<_i189.SaveProfile>(
      () => _i189.SaveProfile(gh<_i679.AuthRepository>()),
    );
    gh.factory<_i1010.SignInWithGoogle>(
      () => _i1010.SignInWithGoogle(gh<_i679.AuthRepository>()),
    );
    gh.factory<_i531.VerifySmsCode>(
      () => _i531.VerifySmsCode(gh<_i679.AuthRepository>()),
    );
    gh.factory<_i113.PostListing>(
      () => _i113.PostListing(gh<_i762.CreateListingRepository>()),
    );
    gh.lazySingleton<_i956.ChatRepository>(
      () => _i279.ChatRepositoryImpl(
        gh<_i584.ChatMockDataSource>(),
        gh<_i904.ListingMockDataSource>(),
        gh<_i263.NetworkInfo>(),
        gh<_i554.Session>(),
      ),
    );
    gh.factory<_i468.GetChatThread>(
      () => _i468.GetChatThread(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i141.GetChats>(
      () => _i141.GetChats(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i191.GetMessages>(
      () => _i191.GetMessages(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i581.GetReturnSummary>(
      () => _i581.GetReturnSummary(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i905.MarkReturned>(
      () => _i905.MarkReturned(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i496.SendMessage>(
      () => _i496.SendMessage(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i956.WatchChats>(
      () => _i956.WatchChats(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i567.NotificationsCubit>(
      () => _i567.NotificationsCubit(
        gh<_i582.GetNotifications>(),
        gh<_i582.MarkAllNotificationsRead>(),
        gh<_i582.MarkNotificationRead>(),
      ),
    );
    gh.factory<_i480.SignInCubit>(
      () => _i480.SignInCubit(
        gh<_i190.RequestSmsCode>(),
        gh<_i1010.SignInWithGoogle>(),
      ),
    );
    gh.factory<_i80.SuccessCubit>(
      () => _i80.SuccessCubit(gh<_i581.GetReturnSummary>()),
    );
    gh.factory<_i126.GetMyProfile>(
      () => _i126.GetMyProfile(gh<_i749.ProfileRepository>()),
    );
    gh.factory<_i126.SetNotifications>(
      () => _i126.SetNotifications(gh<_i749.ProfileRepository>()),
    );
    gh.factory<_i126.SignOut>(
      () => _i126.SignOut(gh<_i749.ProfileRepository>()),
    );
    gh.factory<_i389.ChatListCubit>(
      () => _i389.ChatListCubit(gh<_i141.GetChats>(), gh<_i956.WatchChats>()),
    );
    gh.factory<_i358.ChatCubit>(
      () => _i358.ChatCubit(
        gh<_i468.GetChatThread>(),
        gh<_i191.GetMessages>(),
        gh<_i496.SendMessage>(),
        gh<_i905.MarkReturned>(),
      ),
    );
    gh.factory<_i567.NotificationBadgeCubit>(
      () => _i567.NotificationBadgeCubit(gh<_i582.WatchUnreadNotifications>()),
    );
    gh.factory<_i64.CreateFlowCubit>(
      () => _i64.CreateFlowCubit(gh<_i113.PostListing>()),
    );
    gh.factory<_i176.ClaimCubit>(
      () =>
          _i176.ClaimCubit(gh<_i164.GetClaimTarget>(), gh<_i774.SubmitClaim>()),
    );
    gh.factory<_i64.DetailCubit>(
      () => _i64.DetailCubit(gh<_i445.GetListingDetail>(), gh<_i554.Session>()),
    );
    gh.factory<_i573.ClaimsCubit>(
      () => _i573.ClaimsCubit(
        gh<_i445.GetClaimReview>(),
        gh<_i546.AcceptClaim>(),
        gh<_i695.RejectClaim>(),
      ),
    );
    gh.factory<_i570.ProfileSetupCubit>(
      () =>
          _i570.ProfileSetupCubit(gh<_i189.SaveProfile>(), gh<_i554.Session>()),
    );
    gh.factory<_i533.ProfileCubit>(
      () => _i533.ProfileCubit(
        gh<_i126.GetMyProfile>(),
        gh<_i126.SetNotifications>(),
        gh<_i126.SignOut>(),
        gh<_i592.WatchListings>(),
      ),
    );
    gh.factory<_i684.SmsCodeCubit>(
      () => _i684.SmsCodeCubit(
        gh<_i531.VerifySmsCode>(),
        gh<_i190.RequestSmsCode>(),
      ),
    );
    return this;
  }
}
