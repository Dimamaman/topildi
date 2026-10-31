import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/view_state.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/returned_item.dart';
import '../../domain/usecases/get_listings.dart';
import '../../domain/usecases/get_returned_items.dart';
import '../../domain/usecases/watch_listings.dart';

class FeedState extends Equatable {
  const FeedState({
    this.type = ListingType.found,
    this.filter = const ListingFilter(),
    this.search = '',
    this.view = const ViewLoading(),
    this.returned = const [],
  });

  final ListingType type;
  final ListingFilter filter;
  final String search;
  final ViewState<ListingPage> view;

  /// Recently returned items, newest first. Not filtered by [filter]: the
  /// strip is proof about the whole app, not about this corner of it.
  final List<ReturnedItem> returned;

  /// Fewer than this and the strip stays off the feed entirely — a wall with
  /// two items on it argues against the app rather than for it.
  static const minReturned = 3;

  bool get showReturned => returned.length >= minReturned;

  ListingQuery get query =>
      ListingQuery(type: type, filter: filter, search: search);

  FeedState copyWith({
    ListingType? type,
    ListingFilter? filter,
    String? search,
    ViewState<ListingPage>? view,
    List<ReturnedItem>? returned,
  }) => FeedState(
    type: type ?? this.type,
    filter: filter ?? this.filter,
    search: search ?? this.search,
    view: view ?? this.view,
    returned: returned ?? this.returned,
  );

  @override
  List<Object?> get props => [type, filter, search, view, returned];
}

@injectable
class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._getListings, this._getReturned, WatchListings watch) : super(const FeedState()) {
    _sub = watch().listen((_) {
      load(silent: true);
      loadReturned();
    });
    loadReturned();
  }

  final GetListings _getListings;
  final GetReturnedItems _getReturned;
  late final StreamSubscription<void> _sub;
  Timer? _debounce;
  int _request = 0;

  /// [silent] keeps the current list on screen while refreshing.
  Future<void> load({bool silent = false}) async {
    final id = ++_request;
    if (!silent) emit(state.copyWith(view: const ViewLoading()));
    final result = await _getListings(state.query);
    if (isClosed || id != _request) return;
    emit(
      state.copyWith(
        view: result.fold<ViewState<ListingPage>>(
          (f) => ViewError(f),
          (page) => page.items.isEmpty ? const ViewEmpty() : ViewLoaded(page),
        ),
      ),
    );
  }

  /// The strip is filled beside the feed and never blocks it: a failure
  /// leaves the previous items in place and the strip simply stays as it is.
  Future<void> loadReturned() async {
    final result = await _getReturned(const NoParams());
    if (isClosed) return;
    result.match((_) {}, (items) => emit(state.copyWith(returned: items)));
  }

  void setType(ListingType type) {
    if (type == state.type) return;
    emit(state.copyWith(type: type));
    load();
  }

  /// Category chips: null = all, otherwise exactly one category.
  void setCategory(ItemCategory? category) => setFilter(
    state.filter.copyWith(categories: category == null ? const {} : {category}),
  );

  void setFilter(ListingFilter filter) {
    if (filter == state.filter) return;
    emit(state.copyWith(filter: filter));
    load();
  }

  void resetFilter() => setFilter(const ListingFilter());

  void setSearch(String value) {
    emit(state.copyWith(search: value));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _sub.cancel();
    return super.close();
  }
}

//
