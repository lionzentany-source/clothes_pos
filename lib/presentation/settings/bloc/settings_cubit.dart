import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show ThemeMode; // for theme switching
import 'package:equatable/equatable.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';

class SettingsState extends Equatable {
  final String currency; // e.g., 'LYD'
  final ThemeMode themeMode; // light / dark / system

  const SettingsState({
    required this.currency,
    this.themeMode = ThemeMode.light,
  });

  // Locale fixed to Arabic (app is Arabic-only now)
  Locale get locale => const Locale('ar');

  SettingsState copyWith({String? currency, ThemeMode? themeMode}) =>
      SettingsState(
        currency: currency ?? this.currency,
        themeMode: themeMode ?? this.themeMode,
      );

  @override
  List<Object?> get props => [currency, themeMode];
}

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repo;
  SettingsCubit(this._repo) : super(const SettingsState(currency: 'LYD'));

  Future<void> load() async {
    final cur = await _repo.get('currency') ?? 'LYD';
    if (isClosed) return;
    final modeStr = await _repo.get('themeMode');
    final mode = switch (modeStr) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    emit(SettingsState(currency: cur, themeMode: mode));
  }

  Future<void> setCurrency(String currency) async {
    await _repo.set('currency', currency);
    if (isClosed) return;
    emit(state.copyWith(currency: currency));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repo.set('themeMode', switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      _ => 'light',
    });
    if (isClosed) return;
    emit(state.copyWith(themeMode: mode));
  }
}
