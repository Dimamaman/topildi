import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/listing.dart';
import '../../domain/usecases/get_listings.dart';

class FiltersState extends Equatable {
  const FiltersState({required this.filter, this.count});

  final ListingFilter filter;

  /// Live result count for the CTA; null while counting.
  final int? count;

  @override
  List<Object?> get props => [filter, count];
}

/// Draft filter edited in the sheet; applied to the feed only on confirm.
@injectable
class FiltersCubit extends Cubit<FiltersState> {
  FiltersCubit(this._getListings) : super(const FiltersState(filter: ListingFilter()));

  final GetListings _getListings;
  late ListingType _type;
  late String _search;
  Timer? _debounce;
  int _request = 0;

  void start({required ListingFilter filter, required ListingType type, required String search}) {
    _type = type;
    _search = search;
    _update(filter);
  }

  void toggleCategory(ItemCategory c) {
    final set = {...state.filter.categories};
    set.contains(c) ? set.remove(c) : set.add(c);
    _update(state.filter.copyWith(categories: set));
  }

  void setCity(String city) => _update(state.filter.copyWith(city: city, district: () => null));
  void setDistrict(String? district) => _update(state.filter.copyWith(district: () => district));
  void setPeriod(DatePeriod p) => _update(state.filter.copyWith(period: p));
  void setRange(DateTime from, DateTime to) =>
      _update(state.filter.copyWith(period: DatePeriod.custom, from: from, to: to));
  void reset() => _update(const ListingFilter());

  void _update(ListingFilter f) {
    emit(FiltersState(filter: f));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _count);
  }

  Future<void> _count() async {
    final id = ++_request;
    final r = await _getListings(ListingQuery(type: _type, filter: state.filter, search: _search));
    if (isClosed || id != _request) return;
    emit(FiltersState(filter: state.filter, count: r.fold((_) => null, (p) => p.total)));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
