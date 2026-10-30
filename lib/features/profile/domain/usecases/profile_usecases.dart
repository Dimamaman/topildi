import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/profile_summary.dart';
import '../repositories/profile_repository.dart';

@injectable
class GetMyProfile implements UseCase<ProfileSummary, NoParams> {
  const GetMyProfile(this._repository);
  final ProfileRepository _repository;
  @override
  FutureEither<ProfileSummary> call(NoParams params) => _repository.getMine();
}

@injectable
class SetNotifications implements UseCase<void, bool> {
  const SetNotifications(this._repository);
  final ProfileRepository _repository;
  @override
  FutureEither<void> call(bool params) => _repository.setNotifications(params);
}

@injectable
class SignOut implements UseCase<void, NoParams> {
  const SignOut(this._repository);
  final ProfileRepository _repository;
  @override
  FutureEither<void> call(NoParams params) => _repository.signOut();
}

@injectable
class DeleteAccount implements UseCase<void, NoParams> {
  const DeleteAccount(this._repository);
  final ProfileRepository _repository;
  @override
  FutureEither<void> call(NoParams params) => _repository.deleteAccount();
}
