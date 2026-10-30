import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

/// Deletes the signed-in user's account on the server.
abstract interface class AccountRemoteDataSource {
  Future<void> delete();
}

/// functions/src/account.ts: listings, claims, chats, photos, the profile
/// and (unless FoodZeen uses it) the Auth user.
@prod
@LazySingleton(as: AccountRemoteDataSource)
class FunctionsAccountDataSource implements AccountRemoteDataSource {
  FunctionsAccountDataSource(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<void> delete() => _functions
      .httpsCallable('topildiDeleteAccount', options: HttpsCallableOptions(timeout: const Duration(minutes: 5)))
      .call<Object?>();
}

/// Widget tests: remembers the call.
@test
@LazySingleton(as: AccountRemoteDataSource)
class MockAccountDataSource implements AccountRemoteDataSource {
  bool deleted = false;

  @override
  Future<void> delete() async => deleted = true;
}
