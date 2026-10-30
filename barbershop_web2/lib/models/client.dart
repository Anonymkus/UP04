import 'common.dart';

class ClientCard {
  final String number;
  final int discount;

  const ClientCard({required this.number, required this.discount});

  Map<String, dynamic> toJson() => {'number': number, 'discount': discount};

  factory ClientCard.fromJson(Map<String, dynamic> json) => ClientCard(
    number: jsonString(json['number']),
    discount: jsonInt(json['discount']),
  );
}

class Client implements Entity {
  @override
  final int id;
  final String fullName;
  final String phone;
  final String email;
  final ClientCard card;
  @override
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Client copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? email,
    ClientCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'phone': phone,
    'email': email,
    'card': card.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: jsonInt(json['id']),
    fullName: jsonString(json['fullName']),
    phone: jsonString(json['phone']),
    email: jsonString(json['email']),
    card: json['card'] is Map<String, dynamic>
        ? ClientCard.fromJson(json['card'] as Map<String, dynamic>)
        : const ClientCard(number: '', discount: 0),
    deletedAt: jsonDate(json['deletedAt']),
  );
}
