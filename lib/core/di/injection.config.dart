// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:cloud_functions/cloud_functions.dart' as _i809;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:topildi/core/di/firebase_module.dart' as _i917;
import 'package:topildi/core/l10n/language_cubit.dart' as _i122;
import 'package:topildi/core/links/link_launcher.dart' as _i855;
import 'package:topildi/core/location/location_service.dart' as _i305;
import 'package:topildi/core/map/map_tiles.dart' as _i297;
import 'package:topildi/core/media/app_dirs.dart' as _i706;
import 'package:topildi/core/media/photo_picker.dart' as _i688;
import 'package:topildi/core/network/network_info.dart' as _i263;
import 'package:topildi/core/push/push_service.dart' as _i73;
import 'package:topildi/core/session/session.dart' as _i554;
import 'package:topildi/core/storage/stores.dart' as _i1037;
import 'package:topildi/core/theme/theme_cubit.dart' as _i271;
import 'package:topildi/features/auth/data/repositories/auth_repository_impl.dart'
    as _i597;
import 'package:topildi/features/auth/data/repositories/firebase_auth_repository.dart'
    as _i1033;
import 'package:topildi/features/auth/domain/repositories/auth_repository.dart'
    as _i679;
import 'package:topildi/features/auth/domain/usecases/claim_telegram_login.dart'
    as _i1030;
import 'package:topildi/features/auth/domain/usecases/save_profile.dart'
    as _i189;
import 'package:topildi/features/auth/domain/usecases/sign_in_with_google.dart'
    as _i1010;
import 'package:topildi/features/auth/domain/usecases/start_telegram_login.dart'
    as _i754;
import 'package:topildi/features/auth/presentation/cubit/profile_setup_cubit.dart'
    as _i570;
import 'package:topildi/features/auth/presentation/cubit/sign_in_cubit.dart'
    as _i480;
import 'package:topildi/features/block/data/datasources/block_mock_datasource.dart'
    as _i522;
import 'package:topildi/features/block/data/datasources/block_remote_datasource.dart'
    as _i797;
import 'package:topildi/features/block/data/datasources/firestore_block_datasource.dart'
    as _i647;
import 'package:topildi/features/block/data/repositories/block_repository_impl.dart'
    as _i61;
import 'package:topildi/features/block/domain/repositories/block_repository.dart'
    as _i713;
import 'package:topildi/features/block/domain/usecases/block_user.dart'
    as _i547;
import 'package:topildi/features/block/domain/usecases/get_block_state.dart'
    as _i327;
import 'package:topildi/features/block/domain/usecases/unblock_user.dart'
    as _i628;
import 'package:topildi/features/block/domain/usecases/watch_blocked.dart'
    as _i770;
import 'package:topildi/features/block/presentation/cubit/blocked_cubit.dart'
    as _i165;
import 'package:topildi/features/chat/data/datasources/chat_mock_datasource.dart'
    as _i584;
import 'package:topildi/features/chat/data/datasources/chat_remote_datasource.dart'
    as _i97;
import 'package:topildi/features/chat/data/datasources/firestore_chat_datasource.dart'
    as _i48;
import 'package:topildi/features/chat/data/repositories/chat_repository_impl.dart'
    as _i279;
import 'package:topildi/features/chat/domain/repositories/chat_repository.dart'
    as _i956;
import 'package:topildi/features/chat/domain/usecases/get_chat_thread.dart'
    as _i468;
import 'package:topildi/features/chat/domain/usecases/get_return_summary.dart'
    as _i581;
import 'package:topildi/features/chat/domain/usecases/mark_chat_read.dart'
    as _i354;
import 'package:topildi/features/chat/domain/usecases/mark_returned.dart'
    as _i905;
import 'package:topildi/features/chat/domain/usecases/send_message.dart'
    as _i496;
import 'package:topildi/features/chat/domain/usecases/watch_chat.dart' as _i894;
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
import 'package:topildi/features/claim/data/datasources/claim_remote_datasource.dart'
    as _i1026;
import 'package:topildi/features/claim/data/datasources/firestore_claim_datasource.dart'
    as _i927;
import 'package:topildi/features/claim/data/repositories/claim_repository_impl.dart'
    as _i763;
import 'package:topildi/features/claim/domain/repositories/claim_repository.dart'
    as _i28;
import 'package:topildi/features/claim/domain/usecases/accept_claim.dart'
    as _i546;
import 'package:topildi/features/claim/domain/usecases/cancel_claim.dart'
    as _i77;
import 'package:topildi/features/claim/domain/usecases/get_claim_review.dart'
    as _i445;
import 'package:topildi/features/claim/domain/usecases/get_claim_target.dart'
    as _i164;
import 'package:topildi/features/claim/domain/usecases/reject_claim.dart'
    as _i695;
import 'package:topildi/features/claim/domain/usecases/submit_claim.dart'
    as _i774;
import 'package:topildi/features/claim/domain/usecases/watch_claim.dart'
    as _i857;
import 'package:topildi/features/claim/domain/usecases/watch_pending_claims.dart'
    as _i843;
import 'package:topildi/features/claim/presentation/cubit/claim_cubit.dart'
    as _i176;
import 'package:topildi/features/claim/presentation/cubit/claim_sent_cubit.dart'
    as _i511;
import 'package:topildi/features/claim/presentation/cubit/claims_cubit.dart'
    as _i573;
import 'package:topildi/features/claim/presentation/cubit/pending_claims_cubit.dart'
    as _i142;
import 'package:topildi/features/create_listing/data/repositories/create_listing_repository_impl.dart'
    as _i434;
import 'package:topildi/features/create_listing/domain/repositories/create_listing_repository.dart'
    as _i762;
import 'package:topildi/features/create_listing/domain/usecases/post_listing.dart'
    as _i113;
import 'package:topildi/features/create_listing/domain/usecases/update_listing.dart'
    as _i384;
import 'package:topildi/features/create_listing/presentation/cubit/create_flow_cubit.dart'
    as _i64;
import 'package:topildi/features/listing/data/datasources/firestore_listing_datasource.dart'
    as _i422;
import 'package:topildi/features/listing/data/datasources/listing_mock_datasource.dart'
    as _i904;
import 'package:topildi/features/listing/data/datasources/listing_remote_datasource.dart'
    as _i395;
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
import 'package:topildi/features/listing/domain/usecases/get_returned_items.dart'
    as _i398;
import 'package:topildi/features/listing/domain/usecases/manage_listing.dart'
    as _i487;
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
import 'package:topildi/features/listing/presentation/seen_returned.dart'
    as _i412;
import 'package:topildi/features/notifications/data/datasources/firestore_notification_datasource.dart'
    as _i865;
import 'package:topildi/features/notifications/data/datasources/notification_mock_datasource.dart'
    as _i669;
import 'package:topildi/features/notifications/data/datasources/notification_remote_datasource.dart'
    as _i206;
import 'package:topildi/features/notifications/data/repositories/notification_repository_impl.dart'
    as _i985;
import 'package:topildi/features/notifications/domain/repositories/notification_repository.dart'
    as _i1040;
import 'package:topildi/features/notifications/domain/usecases/notification_usecases.dart'
    as _i582;
import 'package:topildi/features/notifications/presentation/cubit/notifications_cubit.dart'
    as _i567;
import 'package:topildi/features/profile/data/datasources/account_remote_datasource.dart'
    as _i523;
import 'package:topildi/features/profile/data/datasources/consent_remote_datasource.dart'
    as _i788;
import 'package:topildi/features/profile/data/repositories/profile_repository_impl.dart'
    as _i708;
import 'package:topildi/features/profile/domain/repositories/profile_repository.dart'
    as _i749;
import 'package:topildi/features/profile/domain/usecases/profile_usecases.dart'
    as _i126;
import 'package:topildi/features/profile/presentation/cubit/name_consent_cubit.dart'
    as _i247;
import 'package:topildi/features/profile/presentation/cubit/profile_cubit.dart'
    as _i533;
import 'package:topildi/features/report/data/datasources/firestore_report_datasource.dart'
    as _i271;
import 'package:topildi/features/report/data/datasources/report_mock_datasource.dart'
    as _i301;
import 'package:topildi/features/report/data/datasources/report_remote_datasource.dart'
    as _i633;
import 'package:topildi/features/report/data/repositories/report_repository_impl.dart'
    as _i207;
import 'package:topildi/features/report/domain/repositories/report_repository.dart'
    as _i16;
import 'package:topildi/features/report/domain/usecases/check_reported.dart'
    as _i320;
import 'package:topildi/features/report/domain/usecases/submit_report.dart'
    as _i793;
import 'package:topildi/features/report/domain/usecases/watch_report.dart'
    as _i167;

const String _test = 'test';
const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appDirsModule = _$AppDirsModule();
    final storageModule = _$StorageModule();
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<_i73.PushService>(
      () => _i73.NoopPushService(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i523.AccountRemoteDataSource>(
      () => _i523.MockAccountDataSource(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i688.PhotoPicker>(
      () => _i688.FakePhotoPicker(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i305.LocationService>(
      () => _i305.FakeLocationService(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i1037.KeyValueStore>(
      () => _i1037.MemoryKeyValueStore(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i788.ConsentRemoteDataSource>(
      () => _i788.MockConsentDataSource(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i206.NotificationRemoteDataSource>(
      () => _i669.NotificationMockDataSource(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i305.Geocoder>(
      () => _i305.FakeGeocoder(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i633.ReportRemoteDataSource>(
      () => _i301.ReportMockDataSource(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i297.MapTileConfig>(
      () => _i297.NoTiles(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i797.BlockRemoteDataSource>(
      () => _i522.BlockMockDataSource(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i1037.SecureStore>(
      () => _i1037.MemorySecureStore(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i395.ListingRemoteDataSource>(
      () => _i904.ListingMockDataSource(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i263.NetworkInfo>(
      () => _i263.AlwaysOnlineNetworkInfo(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i855.LinkLauncher>(
      () => _i855.RecordingLinkLauncher(),
      registerFor: {_test},
    );
    gh.factory<_i706.AppDirs>(
      () => appDirsModule.testDirs,
      registerFor: {_test},
    );
    gh.lazySingleton<_i263.NetworkInfo>(
      () => _i263.ConnectivityNetworkInfo(),
      registerFor: {_prod},
    );
    await gh.factoryAsync<_i706.AppDirs>(
      () => appDirsModule.dirs,
      registerFor: {_prod},
      preResolve: true,
    );
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => storageModule.prefs,
      registerFor: {_prod},
      preResolve: true,
    );
    gh.factory<_i558.FlutterSecureStorage>(
      () => storageModule.secureStorage,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i59.FirebaseAuth>(
      () => firebaseModule.auth,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i974.FirebaseFirestore>(
      () => firebaseModule.firestore,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i457.FirebaseStorage>(
      () => firebaseModule.storage,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i116.GoogleSignIn>(
      () => firebaseModule.googleSignIn,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i892.FirebaseMessaging>(
      () => firebaseModule.messaging,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i809.FirebaseFunctions>(
      () => firebaseModule.functions,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i97.ChatRemoteDataSource>(
      () => _i584.ChatMockDataSource(gh<_i395.ListingRemoteDataSource>()),
      registerFor: {_test},
    );
    gh.lazySingleton<_i97.ChatRemoteDataSource>(
      () => _i48.FirestoreChatDataSource(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i855.LinkLauncher>(
      () => _i855.UrlLinkLauncher(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i633.ReportRemoteDataSource>(
      () => _i271.FirestoreReportDataSource(gh<_i974.FirebaseFirestore>()),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i206.NotificationRemoteDataSource>(
      () => _i865.FirestoreNotificationDataSource(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i305.LocationService>(
      () => _i305.DeviceLocationService(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i297.MapTileConfig>(
      () => _i297.NetworkTiles(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i688.PhotoPicker>(
      () => _i688.DevicePhotoPicker(gh<_i706.AppDirs>()),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i305.Geocoder>(
      () => _i305.DeviceGeocoder(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i1037.SecureStore>(
      () => _i1037.DeviceSecureStore(gh<_i558.FlutterSecureStorage>()),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i554.Session>(
      () => _i554.LocalSession(
        gh<_i1037.KeyValueStore>(),
        gh<_i1037.SecureStore>(),
        gh<_i706.AppDirs>(),
      ),
      registerFor: {_test},
    );
    gh.lazySingleton<_i1026.ClaimRemoteDataSource>(
      () => _i927.FirestoreClaimDataSource(
        gh<_i974.FirebaseFirestore>(),
        gh<_i457.FirebaseStorage>(),
        gh<_i59.FirebaseAuth>(),
      ),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i395.ListingRemoteDataSource>(
      () => _i422.FirestoreListingDataSource(
        gh<_i974.FirebaseFirestore>(),
        gh<_i457.FirebaseStorage>(),
        gh<_i59.FirebaseAuth>(),
      ),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i523.AccountRemoteDataSource>(
      () => _i523.FunctionsAccountDataSource(gh<_i809.FirebaseFunctions>()),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i1026.ClaimRemoteDataSource>(
      () => _i283.ClaimMockDataSource(gh<_i97.ChatRemoteDataSource>()),
      registerFor: {_test},
    );
    gh.lazySingleton<_i1037.KeyValueStore>(
      () => _i1037.PrefsKeyValueStore(gh<_i460.SharedPreferences>()),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i679.AuthRepository>(
      () => _i597.AuthRepositoryImpl(
        gh<_i554.Session>(),
        gh<_i263.NetworkInfo>(),
      ),
      registerFor: {_test},
    );
    gh.lazySingleton<_i797.BlockRemoteDataSource>(
      () => _i647.FirestoreBlockDataSource(gh<_i974.FirebaseFirestore>()),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i122.LanguageCubit>(
      () => _i122.LanguageCubit(gh<_i1037.KeyValueStore>()),
    );
    gh.lazySingleton<_i271.ThemeCubit>(
      () => _i271.ThemeCubit(gh<_i1037.KeyValueStore>()),
    );
    gh.lazySingleton<_i412.SeenReturned>(
      () => _i412.SeenReturned(gh<_i1037.KeyValueStore>()),
    );
    gh.lazySingleton<_i788.ConsentRemoteDataSource>(
      () => _i788.FirestoreConsentDataSource(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i1040.NotificationRepository>(
      () => _i985.NotificationRepositoryImpl(
        gh<_i206.NotificationRemoteDataSource>(),
        gh<_i263.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i73.PushService>(
      () => _i73.FirebasePushService(
        gh<_i892.FirebaseMessaging>(),
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
        gh<_i1037.KeyValueStore>(),
        gh<_i122.LanguageCubit>(),
      ),
      registerFor: {_prod},
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
    gh.factory<_i567.NotificationsCubit>(
      () => _i567.NotificationsCubit(
        gh<_i582.GetNotifications>(),
        gh<_i582.MarkAllNotificationsRead>(),
        gh<_i582.MarkNotificationRead>(),
      ),
    );
    gh.lazySingleton<_i554.Session>(
      () => _i554.FirebaseSession(
        gh<_i1037.KeyValueStore>(),
        gh<_i1037.SecureStore>(),
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
      ),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i762.CreateListingRepository>(
      () => _i434.CreateListingRepositoryImpl(
        gh<_i395.ListingRemoteDataSource>(),
        gh<_i263.NetworkInfo>(),
        gh<_i554.Session>(),
      ),
    );
    gh.lazySingleton<_i749.ProfileRepository>(
      () => _i708.ProfileRepositoryImpl(
        gh<_i395.ListingRemoteDataSource>(),
        gh<_i1026.ClaimRemoteDataSource>(),
        gh<_i554.Session>(),
        gh<_i263.NetworkInfo>(),
        gh<_i1037.KeyValueStore>(),
        gh<_i73.PushService>(),
        gh<_i523.AccountRemoteDataSource>(),
        gh<_i788.ConsentRemoteDataSource>(),
      ),
    );
    gh.factory<_i126.GetMyProfile>(
      () => _i126.GetMyProfile(gh<_i749.ProfileRepository>()),
    );
    gh.factory<_i126.SetNotifications>(
      () => _i126.SetNotifications(gh<_i749.ProfileRepository>()),
    );
    gh.factory<_i126.GetShowNameOnReturns>(
      () => _i126.GetShowNameOnReturns(gh<_i749.ProfileRepository>()),
    );
    gh.factory<_i126.SetShowNameOnReturns>(
      () => _i126.SetShowNameOnReturns(gh<_i749.ProfileRepository>()),
    );
    gh.factory<_i126.SignOut>(
      () => _i126.SignOut(gh<_i749.ProfileRepository>()),
    );
    gh.factory<_i126.DeleteAccount>(
      () => _i126.DeleteAccount(gh<_i749.ProfileRepository>()),
    );
    gh.lazySingleton<_i679.AuthRepository>(
      () => _i1033.FirebaseAuthRepository(
        gh<_i59.FirebaseAuth>(),
        gh<_i974.FirebaseFirestore>(),
        gh<_i457.FirebaseStorage>(),
        gh<_i809.FirebaseFunctions>(),
        gh<_i116.GoogleSignIn>(),
        gh<_i554.Session>(),
        gh<_i263.NetworkInfo>(),
      ),
      registerFor: {_prod},
    );
    gh.factory<_i567.NotificationBadgeCubit>(
      () => _i567.NotificationBadgeCubit(gh<_i582.WatchUnreadNotifications>()),
    );
    gh.lazySingleton<_i16.ReportRepository>(
      () => _i207.ReportRepositoryImpl(
        gh<_i633.ReportRemoteDataSource>(),
        gh<_i263.NetworkInfo>(),
        gh<_i554.Session>(),
      ),
    );
    gh.lazySingleton<_i856.ListingRepository>(
      () => _i786.ListingRepositoryImpl(
        gh<_i395.ListingRemoteDataSource>(),
        gh<_i797.BlockRemoteDataSource>(),
        gh<_i263.NetworkInfo>(),
        gh<_i554.Session>(),
      ),
    );
    gh.lazySingleton<_i956.ChatRepository>(
      () => _i279.ChatRepositoryImpl(
        gh<_i97.ChatRemoteDataSource>(),
        gh<_i263.NetworkInfo>(),
        gh<_i554.Session>(),
      ),
    );
    gh.lazySingleton<_i28.ClaimRepository>(
      () => _i763.ClaimRepositoryImpl(
        gh<_i1026.ClaimRemoteDataSource>(),
        gh<_i395.ListingRemoteDataSource>(),
        gh<_i263.NetworkInfo>(),
        gh<_i554.Session>(),
      ),
    );
    gh.factory<_i1030.ClaimTelegramLogin>(
      () => _i1030.ClaimTelegramLogin(gh<_i679.AuthRepository>()),
    );
    gh.factory<_i189.SaveProfile>(
      () => _i189.SaveProfile(gh<_i679.AuthRepository>()),
    );
    gh.factory<_i1010.SignInWithGoogle>(
      () => _i1010.SignInWithGoogle(gh<_i679.AuthRepository>()),
    );
    gh.factory<_i754.StartTelegramLogin>(
      () => _i754.StartTelegramLogin(gh<_i679.AuthRepository>()),
    );
    gh.factory<_i113.PostListing>(
      () => _i113.PostListing(gh<_i762.CreateListingRepository>()),
    );
    gh.factory<_i384.UpdateListing>(
      () => _i384.UpdateListing(gh<_i762.CreateListingRepository>()),
    );
    gh.lazySingleton<_i713.BlockRepository>(
      () => _i61.BlockRepositoryImpl(
        gh<_i797.BlockRemoteDataSource>(),
        gh<_i263.NetworkInfo>(),
        gh<_i554.Session>(),
      ),
    );
    gh.factory<_i468.GetChatThread>(
      () => _i468.GetChatThread(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i581.GetReturnSummary>(
      () => _i581.GetReturnSummary(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i354.MarkChatRead>(
      () => _i354.MarkChatRead(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i905.MarkReturned>(
      () => _i905.MarkReturned(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i496.SendMessage>(
      () => _i496.SendMessage(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i894.WatchChat>(
      () => _i894.WatchChat(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i956.WatchChats>(
      () => _i956.WatchChats(gh<_i956.ChatRepository>()),
    );
    gh.factory<_i247.NameConsentCubit>(
      () => _i247.NameConsentCubit(
        gh<_i126.GetShowNameOnReturns>(),
        gh<_i126.SetShowNameOnReturns>(),
      ),
    );
    gh.factory<_i320.CheckReported>(
      () => _i320.CheckReported(gh<_i16.ReportRepository>()),
    );
    gh.factory<_i793.SubmitReport>(
      () => _i793.SubmitReport(gh<_i16.ReportRepository>()),
    );
    gh.factory<_i167.WatchReport>(
      () => _i167.WatchReport(gh<_i16.ReportRepository>()),
    );
    gh.factory<_i80.SuccessCubit>(
      () => _i80.SuccessCubit(gh<_i581.GetReturnSummary>()),
    );
    gh.factory<_i570.ProfileSetupCubit>(
      () => _i570.ProfileSetupCubit(
        gh<_i189.SaveProfile>(),
        gh<_i554.Session>(),
        gh<_i126.DeleteAccount>(),
      ),
    );
    gh.factory<_i389.ChatListCubit>(
      () => _i389.ChatListCubit(gh<_i956.WatchChats>()),
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
    gh.factory<_i398.GetReturnedItems>(
      () => _i398.GetReturnedItems(gh<_i856.ListingRepository>()),
    );
    gh.factory<_i487.DeleteListing>(
      () => _i487.DeleteListing(gh<_i856.ListingRepository>()),
    );
    gh.factory<_i487.MarkListingReturned>(
      () => _i487.MarkListingReturned(gh<_i856.ListingRepository>()),
    );
    gh.factory<_i592.WatchListings>(
      () => _i592.WatchListings(gh<_i856.ListingRepository>()),
    );
    gh.factory<_i480.SignInCubit>(
      () => _i480.SignInCubit(
        gh<_i754.StartTelegramLogin>(),
        gh<_i1030.ClaimTelegramLogin>(),
        gh<_i263.NetworkInfo>(),
        gh<_i855.LinkLauncher>(),
      ),
    );
    gh.factory<_i547.BlockUser>(
      () => _i547.BlockUser(gh<_i713.BlockRepository>()),
    );
    gh.factory<_i327.GetBlockState>(
      () => _i327.GetBlockState(gh<_i713.BlockRepository>()),
    );
    gh.factory<_i628.UnblockUser>(
      () => _i628.UnblockUser(gh<_i713.BlockRepository>()),
    );
    gh.factory<_i770.WatchBlocked>(
      () => _i770.WatchBlocked(gh<_i713.BlockRepository>()),
    );
    gh.factory<_i534.FiltersCubit>(
      () => _i534.FiltersCubit(gh<_i1022.GetListings>()),
    );
    gh.factory<_i546.AcceptClaim>(
      () => _i546.AcceptClaim(gh<_i28.ClaimRepository>()),
    );
    gh.factory<_i77.CancelClaim>(
      () => _i77.CancelClaim(gh<_i28.ClaimRepository>()),
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
    gh.factory<_i857.WatchClaim>(
      () => _i857.WatchClaim(gh<_i28.ClaimRepository>()),
    );
    gh.factory<_i843.WatchPendingClaims>(
      () => _i843.WatchPendingClaims(gh<_i28.ClaimRepository>()),
    );
    gh.factory<_i446.MapCubit>(
      () => _i446.MapCubit(
        gh<_i619.GetMapListings>(),
        gh<_i305.LocationService>(),
        gh<_i592.WatchListings>(),
      ),
    );
    gh.factory<_i516.FeedCubit>(
      () => _i516.FeedCubit(
        gh<_i1022.GetListings>(),
        gh<_i398.GetReturnedItems>(),
        gh<_i592.WatchListings>(),
      ),
    );
    gh.factory<_i533.ProfileCubit>(
      () => _i533.ProfileCubit(
        gh<_i126.GetMyProfile>(),
        gh<_i126.SetNotifications>(),
        gh<_i126.SetShowNameOnReturns>(),
        gh<_i126.SignOut>(),
        gh<_i592.WatchListings>(),
        gh<_i843.WatchPendingClaims>(),
      ),
    );
    gh.factory<_i358.ChatCubit>(
      () => _i358.ChatCubit(
        gh<_i894.WatchChat>(),
        gh<_i354.MarkChatRead>(),
        gh<_i496.SendMessage>(),
        gh<_i905.MarkReturned>(),
        gh<_i445.GetListingDetail>(),
        gh<_i327.GetBlockState>(),
      ),
    );
    gh.factory<_i64.CreateFlowCubit>(
      () => _i64.CreateFlowCubit(
        gh<_i113.PostListing>(),
        gh<_i384.UpdateListing>(),
        gh<_i445.GetClaimReview>(),
      ),
    );
    gh.factory<_i64.DetailCubit>(
      () => _i64.DetailCubit(
        gh<_i445.GetListingDetail>(),
        gh<_i554.Session>(),
        gh<_i445.GetClaimReview>(),
        gh<_i164.GetClaimTarget>(),
        gh<_i487.DeleteListing>(),
        gh<_i487.MarkListingReturned>(),
        gh<_i77.CancelClaim>(),
      ),
    );
    gh.factory<_i176.ClaimCubit>(
      () =>
          _i176.ClaimCubit(gh<_i164.GetClaimTarget>(), gh<_i774.SubmitClaim>()),
    );
    gh.factory<_i142.PendingClaimsCubit>(
      () => _i142.PendingClaimsCubit(gh<_i843.WatchPendingClaims>()),
    );
    gh.factory<_i511.ClaimSentCubit>(
      () => _i511.ClaimSentCubit(gh<_i857.WatchClaim>()),
    );
    gh.factory<_i573.ClaimsCubit>(
      () => _i573.ClaimsCubit(
        gh<_i445.GetClaimReview>(),
        gh<_i546.AcceptClaim>(),
        gh<_i695.RejectClaim>(),
      ),
    );
    gh.factory<_i165.BlockedCubit>(
      () => _i165.BlockedCubit(
        gh<_i770.WatchBlocked>(),
        gh<_i628.UnblockUser>(),
        gh<_i547.BlockUser>(),
      ),
    );
    return this;
  }
}

class _$AppDirsModule extends _i706.AppDirsModule {}

class _$StorageModule extends _i1037.StorageModule {}

class _$FirebaseModule extends _i917.FirebaseModule {}
