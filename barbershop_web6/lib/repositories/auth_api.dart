import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/user.dart';

class Session {
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  const Session(this.accessToken, this.refreshToken, this.user);

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    json['accessToken'] as String? ?? '',
    json['refreshToken'] as String? ?? '',
    AppUser.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
  );
}

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<Session> login(String username, String password) => guard(() async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return Session.fromJson(response.data as Map<String, dynamic>);
  });

  Future<void> register(Map<String, String> data) =>
      guard(() => _dio.post('/auth/register', data: data));

  Future<Session> refresh(String refreshToken) => guard(() async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return Session.fromJson(response.data as Map<String, dynamic>);
  });

  Future<void> logout(String refreshToken) => guard(
    () => _dio.post('/auth/logout', data: {'refreshToken': refreshToken}),
  );
}

class AdminApi {
  final Dio _dio;

  AdminApi(this._dio);

  Future<List<AppUser>> users() => guard(() async {
    final response = await _dio.get('/users');
    final items = (response.data as Map<String, dynamic>)['items'] as List;
    return [
      for (final e in items)
        if (e is Map<String, dynamic>) AppUser.fromJson(e),
    ];
  });

  Future<void> setRole(int userId, Role role) =>
      guard(() => _dio.put('/users/$userId/role', data: {'role': role.name}));

  Future<Map<String, dynamic>> stats() => guard(() async {
    final response = await _dio.get('/stats');
    return response.data as Map<String, dynamic>;
  });
}
