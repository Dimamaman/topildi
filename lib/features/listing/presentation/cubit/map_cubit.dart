import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/view_state.dart';
import '../../domain/entities/listing.dart';
import '../../domain/usecases/get_map_listings.dart';
import '../../domain/usecases/watch_listings.dart';

class MapState extends Equatable {
  const MapState({
    this.view = const ViewLoading(),
    this.filter = const ListingFilter(),
    this.showFound = true,
    this.showLost = true,
    this.search = '',
    this.selectedId,
  });

  final ViewState<List<Listing>> view;
  final ListingFilter filter;
  final bool showFound, showLost;
  final String search;
  final String? selectedId;

  List<Listing> get all => switch (view) {
        ViewLoaded(:final data) => data,
        _ => const [],
      };

  /// Pins currently drawn, after the type toggles and the search box.
  List<Listing> get visible {
    final q = search.trim().toLowerCase();
    return all
        .where((l) => l.isFound ? showFound : showLost)
        .where((l) => q.isEmpty || l.title.toLowerCase().contains(q) || l.areaName.toLowerCase().contains(q))
        .toList();
  }

  int count(ListingType t) => all.where((l) => l.type == t).length;

  Listing? get selected {
    for (final l in visible) {
      if (l.id == selectedId) return l;
    }
    return null;
  }

  MapState copyWith({
    ViewState<List<Listing>>? view,
    ListingFilter? filter,
    bool? showFound,
    bool? showLost,
    String? search,
    String? Function()? selectedId,
  }) =>
      MapState(
        view: view ?? this.view,
        filter: filter ?? this.filter,
        showFound: showFound ?? this.showFound,
        showLost: showLost ?? this.showLost,
        search: search ?? this.search,
        selectedId: selectedId != null ? selectedId() : this.selectedId,
      );

  @override
  List<Object?> get props => [view, filter, showFound, showLost, search, selectedId];
}

@injectable
class MapCubit extends Cubit<MapState> {
  MapCubit(this._get, WatchListings watch) : super(const MapState()) {
    _sub = watch().listen((_) => load(silent: true));
  }

  /// Mock "my location" (Chilonzor metro) until location permission exists.
  static const myLat = 41.2856, myLng = 69.2034;

  final GetMapListings _get;
  late final StreamSubscription<void> _sub;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(view: const ViewLoading()));
    final r = await _get(state.filter);
    if (isClosed) return;
    emit(state.copyWith(
      view: r.fold<ViewState<List<Listing>>>((f) => ViewError(f), (l) => l.isEmpty ? const ViewEmpty() : ViewLoaded(l)),
    ));
    if (state.selected == null) selectNearest();
  }

  void select(String id) => emit(state.copyWith(selectedId: () => id));

  void selectNearest() {
    final v = state.visible;
    if (v.isEmpty) return emit(state.copyWith(selectedId: () => null));
    v.sort((a, b) => distanceTo(a).compareTo(distanceTo(b)));
    select(v.first.id);
  }

  void toggleFound() => _toggled(state.copyWith(showFound: !state.showFound));
  void toggleLost() => _toggled(state.copyWith(showLost: !state.showLost));
  void setSearch(String v) => _toggled(state.copyWith(search: v));

  void _toggled(MapState next) {
    emit(next);
    if (next.selected == null) selectNearest();
  }

  void setFilter(ListingFilter f) {
    if (f == state.filter) return;
    emit(state.copyWith(filter: f));
    load();
  }

  /// Metres from "my location" to the area centre.
  static double distanceTo(Listing l) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(l.lat - myLat);
    final dLng = rad(l.lng - myLng);
    final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(myLat)) * math.cos(rad(l.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
