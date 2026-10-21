import 'common.dart';

class Service implements Entity {
  @override
  final int id;
  final String name;
  final int price;
  final int duration;
  @override
  final DateTime? deletedAt;

  const Service({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Service copyWith({
    int? id,
    String? name,
    int? price,
    int? duration,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'duration': duration,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: jsonInt(json['id']),
    name: jsonString(json['name']),
    price: jsonInt(json['price']),
    duration: jsonInt(json['duration']),
    deletedAt: jsonDate(json['deletedAt']),
  );
}
