import 'common.dart';

class Branch implements Entity {
  @override
  final int id;
  final String name;
  final String address;
  @override
  final DateTime? deletedAt;

  const Branch({
    required this.id,
    required this.name,
    required this.address,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Branch copyWith({
    int? id,
    String? name,
    String? address,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Branch withId(int id) => copyWith(id: id);

  @override
  Branch withDeletedAt(DateTime? deletedAt) => deletedAt == null
      ? copyWith(clearDeletedAt: true)
      : copyWith(deletedAt: deletedAt);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
    id: jsonInt(json['id']),
    name: jsonString(json['name']),
    address: jsonString(json['address']),
    deletedAt: jsonDate(json['deletedAt']),
  );
}
