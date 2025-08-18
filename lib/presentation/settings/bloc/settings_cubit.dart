import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';

class SettingsState extends Equatable {
  final String localeCode; // 'ar' or 'en'
  final String currency; // e.g., 'LYD'

  const SettingsState({required this.localeCode, required this.currency});

  Locale get locale => Locale(localeCode);

  SettingsState copyWith({String? localeCode, String? currency}) =>
      SettingsState(
        localeCode: localeCode ?? this.localeCode,
        currency: currency ?? this.currency,
      );

  @override
  List<Object?> get props => [localeCode, currency];
}

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repo;
  SettingsCubit(this._repo)
    : super(const SettingsState(localeCode: 'ar', currency: 'LYD'));

  Future<void> load() async {
    final loc = await _repo.get('app_locale') ?? 'ar';
    final cur = await _repo.get('currency') ?? 'LYD';
    if (isClosed) return;
    emit(SettingsState(localeCode: loc, currency: cur));
  }

  Future<void> setLocale(String localeCode) async {
    await _repo.set('app_locale', localeCode);
    if (isClosed) return;
    emit(state.copyWith(localeCode: localeCode));
  }

  Future<void> setCurrency(String currency) async {
    await _repo.set('currency', currency);
    if (isClosed) return;
    emit(state.copyWith(currency: currency));
  }
}
