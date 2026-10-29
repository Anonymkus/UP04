import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../repositories/auth_api.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user';
  static const _kStarted = 'auth_started_at';
  static const sessionLimit = Duration(minutes: 30);

  final SharedPreferences _prefs;
  final AuthApi _api;

  AuthNotifier(this._prefs, this._api);

  AppUser? _user;
  String? _accessToken;
  String? message;
  Timer? _sessionTimer;
  Future<bool>? _refreshing;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;
  Role? get role => _user?.role;

  bool has(Role role) => _user != null && _user!.role.level >= role.level;

  void restore() {
    final access = _prefs.getString(_kAccess);
    final userJson = _prefs.getString(_kUser);
    final started = DateTime.tryParse(_prefs.getString(_kStarted) ?? '');
    if (access == null || userJson == null || started == null) return;
    try {
      _user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      _clear();
      return;
    }
    _accessToken = access;
    _startSessionTimer(started);
  }

  Future<void> login(String username, String password) async {
    final session = await _api.login(username, password);
    final started = DateTime.now();
    await _save(session);
    await _prefs.setString(_kStarted, started.toIso8601String());
    message = null;
    _startSessionTimer(started);
    notifyListeners();
  }

  Future<void> register(Map<String, String> data) async {
    await _api.register(data);
    await login(data['username']!, data['password']!);
  }

  Future<bool> refreshTokens() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final refresh = _prefs.getString(_kRefresh);
    if (refresh == null) return false;
    try {
      await _save(await _api.refresh(refresh));
      return true;
    } catch (_) {
      await logout(reason: 'Сессия истекла. Войдите снова.');
      return false;
    }
  }

  Future<void> logout({String? reason}) async {
    final refresh = _prefs.getString(_kRefresh);
    if (refresh != null && reason == null) {
      _api.logout(refresh).ignore();
    }
    message = reason;
    _clear();
    notifyListeners();
  }

  Future<void> _save(Session session) async {
    _accessToken = session.accessToken;
    _user = session.user;
    await _prefs.setString(_kAccess, session.accessToken);
    await _prefs.setString(_kRefresh, session.refreshToken);
    await _prefs.setString(_kUser, jsonEncode(session.user.toJson()));
  }

  void _startSessionTimer(DateTime started) {
    _sessionTimer?.cancel();
    final left = started.add(sessionLimit).difference(DateTime.now());
    _sessionTimer = Timer(
      left.isNegative ? Duration.zero : left,
      () => logout(reason: 'Время сессии (30 минут) истекло. Войдите снова.'),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _clear() {
    _sessionTimer?.cancel();
    _user = null;
    _accessToken = null;
    for (final key in [_kAccess, _kRefresh, _kUser, _kStarted]) {
      _prefs.remove(key);
    }
  }
}
