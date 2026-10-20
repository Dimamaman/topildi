import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/session/session.dart';
import '../../../../core/view_state.dart';
import '../../domain/entities/listing.dart';
import '../../domain/usecases/get_listing_detail.dart';

class DetailState extends Equatable {
  const DetailState({this.view = const ViewLoading(), this.photoIndex = 0, this.isMine = false});

  final ViewState<Listing> view;
  final int photoIndex;

  /// The signed-in user authored this listing (shows claims instead of "Bu meniki").
  final bool isMine;

  DetailState copyWith({ViewState<Listing>? view, int? photoIndex, bool? isMine}) => DetailState(
        view: view ?? this.view,
        photoIndex: photoIndex ?? this.photoIndex,
        isMine: isMine ?? this.isMine,
      );

  @override
  List<Object?> get props => [view, photoIndex, isMine];
}

@injectable
class DetailCubit extends Cubit<DetailState> {
  DetailCubit(this._getDetail, this._session) : super(const DetailState());

  final GetListingDetail _getDetail;
  final Session _session;

  Future<void> load(String id) async {
    emit(state.copyWith(view: const ViewLoading()));
    final result = await _getDetail(id);
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(view: ViewError(f))),
      (l) => emit(state.copyWith(view: ViewLoaded(l), isMine: l.author.id == _session.userId)),
    );
  }

  void selectPhoto(int index) => emit(state.copyWith(photoIndex: index));
}
