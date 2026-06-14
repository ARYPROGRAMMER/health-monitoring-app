import 'package:flutter_bloc/flutter_bloc.dart';

enum LoadStatus { loading, success, failure }

/// A generic async value: status + data + error. Used by the focused cubits
/// that back secondary detail screens (location, SOS, ECG, device info).
class Async<T> {
  const Async({this.status = LoadStatus.loading, this.data, this.error});

  final LoadStatus status;
  final T? data;
  final String? error;

  bool get isLoading => status == LoadStatus.loading;
  bool get isSuccess => status == LoadStatus.success;
  bool get isFailure => status == LoadStatus.failure;

  Async<T> loading() => Async<T>(status: LoadStatus.loading, data: data);
  Async<T> success(T value) => Async<T>(status: LoadStatus.success, data: value);
  Async<T> failure(String message) =>
      Async<T>(status: LoadStatus.failure, data: data, error: message);
}

/// A reusable cubit that runs a single loader and surfaces it as [Async].
/// Keeps each secondary screen backed by its own BLoC with zero boilerplate.
class LoadCubit<T> extends Cubit<Async<T>> {
  LoadCubit(this._loader) : super(Async<T>());

  final Future<T> Function() _loader;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.loading());
    try {
      emit(state.success(await _loader()));
    } catch (e) {
      emit(state.failure(_message(e)));
    }
  }

  String _message(Object e) {
    final text = e.toString();
    return text.length > 200 ? '${text.substring(0, 200)}…' : text;
  }
}
