import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/location/geo_point.dart';
import '../../../../core/location/location_service.dart';
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
    this.me = GeoPoint.tashkent,
    this.hasFix = false,
    this.locationProblem,
  });

  /// Device position (stays on-device; only used for distances and centring).
  final GeoPoint me;
  final bool hasFix;
  final LocationProblem? locationProblem;

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
    GeoPoint? me,
    bool? hasFix,
    LocationProblem? locationProblem,
  }) =>
      MapState(
        view: view ?? this.view,
        filter: filter ?? this.filter,
        showFound: showFound ?? this.showFound,
        showLost: showLost ?? this.showLost,
        search: search ?? this.search,
        selectedId: selectedId != null ? selectedId() : this.selectedId,
        me: me ?? this.me,
        hasFix: hasFix ?? this.hasFix,
        locationProblem: locationProblem,
      );

  double distanceTo(Listing l) => me.distanceTo(l.area);

  @override
  List<Object?> get props => [view, filter, showFound, showLost, search, selectedId, me, hasFix, locationProblem];
}

@injectable
class MapCubit extends Cubit<MapState> {
  MapCubit(this._get, this._location, WatchListings watch) : super(const MapState()) {
    _sub = watch().listen((_) => load(silent: true));
  }

  final GetMapListings _get;
  final LocationService _location;
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
    v.sort((a, b) => state.distanceTo(a).compareTo(state.distanceTo(b)));
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

  /// Updates "my location"; returns the fix, or null with [MapState.locationProblem] set.
  Future<GeoPoint?> locate() async {
    final r = await _location.current();
    if (isClosed) return null;
    return r.match(
      (p) {
        emit(state.copyWith(locationProblem: p));
        return null;
      },
      (g) {
        emit(state.copyWith(me: g, hasFix: true));
        selectNearest();
        return g;
      },
    );
  }

  Future<void> openLocationSettings() => _location.openSettings();

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
