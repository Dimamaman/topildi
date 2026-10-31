import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/profile_usecases.dart';

/// The "Ismim koʻrinsin" switch, wherever it is shown. Off is the default and
/// also what a failed write falls back to: the name must never look shown
/// while the listings do not carry it.
@injectable
class NameConsentCubit extends Cubit<bool> {
  NameConsentCubit(this._get, this._set) : super(false);

  final GetShowNameOnReturns _get;
  final SetShowNameOnReturns _set;

  Future<void> load() async {
    final r = await _get(const NoParams());
    if (isClosed) return;
    r.match((_) {}, (on) => emit(on));
  }

  /// The switch moves at once and comes back if the write did not land.
  Future<void> set(bool on) async {
    final before = state;
    emit(on);
    final r = await _set(on);
    if (isClosed) return;
    r.match((_) => emit(before), (_) {});
  }
}
