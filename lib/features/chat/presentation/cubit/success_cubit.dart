import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/view_state.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/get_return_summary.dart';

@injectable
class SuccessCubit extends Cubit<ViewState<ReturnSummary>> {
  SuccessCubit(this._get) : super(const ViewLoading());

  final GetReturnSummary _get;

  Future<void> load(String chatId) async {
    emit(const ViewLoading());
    final r = await _get(chatId);
    if (isClosed) return;
    emit(r.fold<ViewState<ReturnSummary>>((f) => ViewError(f), ViewLoaded.new));
  }
}
