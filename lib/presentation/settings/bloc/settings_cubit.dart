import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show ThemeMode; // for theme switching
import 'package:equatable/equatable.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';

class SettingsState extends Equatable {
  final String currency; // e.g., 'LYD'
  final ThemeMode themeMode; // light / dark / system
  final String? facebookPageAccessToken;
  final String? facebookVerifyToken;
  final String? facebookPageId;
  final bool showProductCardImage; // Toggle for showing product images in POS

  const SettingsState({
    required this.currency,
    this.themeMode = ThemeMode.light,
    this.facebookPageAccessToken,
    this.facebookVerifyToken,
    this.facebookPageId,
    this.showProductCardImage = true, // default to showing images
  });

  // Locale fixed to Arabic (app is Arabic-only now)
  Locale get locale => const Locale('ar');

  SettingsState copyWith({
    String? currency,
    ThemeMode? themeMode,
    String? facebookPageAccessToken,
    String? facebookVerifyToken,
    String? facebookPageId,
    bool? showProductCardImage,
  }) => SettingsState(
    currency: currency ?? this.currency,
    themeMode: themeMode ?? this.themeMode,
    facebookPageAccessToken:
        facebookPageAccessToken ?? this.facebookPageAccessToken,
    facebookVerifyToken: facebookVerifyToken ?? this.facebookVerifyToken,
    facebookPageId: facebookPageId ?? this.facebookPageId,
    showProductCardImage: showProductCardImage ?? this.showProductCardImage,
  );

  @override
  List<Object?> get props => [
    currency,
    themeMode,
    facebookPageAccessToken,
    facebookVerifyToken,
    facebookPageId,
    showProductCardImage,
  ];
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
    final accessToken = await _repo.get('facebook_page_access_token');
    final verifyToken = await _repo.get('facebook_verify_token');
    final pageId = await _repo.get('facebook_page_id');
    emit(
      SettingsState(
        currency: cur,
        themeMode: mode,
        facebookPageAccessToken: accessToken,
        facebookVerifyToken: verifyToken,
        facebookPageId: pageId,
      ),
    );
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

  Future<void> setFacebookPageAccessToken(String? token) async {
    await _repo.set('facebook_page_access_token', token);
    if (isClosed) return;
    emit(state.copyWith(facebookPageAccessToken: token));
  }

  Future<void> setFacebookVerifyToken(String? token) async {
    await _repo.set('facebook_verify_token', token);
    if (isClosed) return;
    emit(state.copyWith(facebookVerifyToken: token));
  }

  Future<void> setFacebookPageId(String? id) async {
    await _repo.set('facebook_page_id', id);
    if (isClosed) return;
    emit(state.copyWith(facebookPageId: id));
  }
}
