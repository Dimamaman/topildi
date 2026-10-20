import 'package:equatable/equatable.dart';

import 'error/failure.dart';

/// Shared four-state model for list/detail screens.
sealed class ViewState<T> extends Equatable {
  const ViewState();

  @override
  List<Object?> get props => [];
}

class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

class ViewLoaded<T> extends ViewState<T> {
  const ViewLoaded(this.data);
  final T data;

  @override
  List<Object?> get props => [data];
}

class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}

class ViewError<T> extends ViewState<T> {
  const ViewError(this.failure);
  final Failure failure;

  bool get isOffline => failure is NetworkFailure;

  @override
  List<Object?> get props => [failure];
}
