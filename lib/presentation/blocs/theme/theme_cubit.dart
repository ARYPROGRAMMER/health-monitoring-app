import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/cache_keys.dart';
import '../../../core/theme/app_accent.dart';
import '../../../data/services/cache_service.dart';

class ThemeState extends Equatable {
  const ThemeState({required this.mode, required this.accent});

  final ThemeMode mode;
  final AppAccent accent;

  bool get isDark => mode == ThemeMode.dark;

  ThemeState copyWith({ThemeMode? mode, AppAccent? accent}) =>
      ThemeState(mode: mode ?? this.mode, accent: accent ?? this.accent);

  @override
  List<Object?> get props => [mode, accent];
}

/// Local source of truth for appearance: dark/light + accent identity,
/// persisted in the Hive cache. Backend `darkMode` is reconciled by the UI.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._cache) : super(_load(_cache));

  final CacheService _cache;

  static ThemeState _load(CacheService cache) {
    final mode = cache.readString(CacheKeys.themeMode) == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;
    return ThemeState(
      mode: mode,
      accent: AppAccentX.fromName(cache.readString(CacheKeys.accent)),
    );
  }

  void setDark(bool dark) {
    final mode = dark ? ThemeMode.dark : ThemeMode.light;
    if (mode == state.mode) return;
    emit(state.copyWith(mode: mode));
    _cache.writeString(CacheKeys.themeMode, dark ? 'dark' : 'light');
  }

  void setAccent(AppAccent accent) {
    if (accent == state.accent) return;
    emit(state.copyWith(accent: accent));
    _cache.writeString(CacheKeys.accent, accent.name);
  }
}
