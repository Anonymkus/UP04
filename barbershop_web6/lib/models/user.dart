import 'common.dart';

enum Role {
  client(1, 'Клиент'),
  manager(2, 'Менеджер'),
  admin(3, 'Администратор');

  final int level;
  final String title;

  const Role(this.level, this.title);

  static Role parse(Object? value) =>
      Role.values.firstWhere((r) => r.name == value, orElse: () => Role.client);
}

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final Role role;
  final int? clientId;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.clientId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'role': role.name,
    'clientId': clientId,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: jsonInt(json['id']),
    username: jsonString(json['username']),
    fullName: jsonString(json['fullName']),
    role: Role.parse(json['role']),
    clientId: json['clientId'] is int ? json['clientId'] as int : null,
  );
}
