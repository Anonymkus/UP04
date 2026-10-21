import 'common.dart';

class Barber implements Entity {
  @override
  final int id;
  final String fullName;
  final int birthYear;
  final int branchId;
  @override
  final DateTime? deletedAt;

  const Barber({
    required this.id,
    required this.fullName,
    required this.birthYear,
    required this.branchId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Barber copyWith({
    int? id,
    String? fullName,
    int? birthYear,
    int? branchId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Barber(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      birthYear: birthYear ?? this.birthYear,
      branchId: branchId ?? this.branchId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'birthYear': birthYear,
    'branchId': branchId,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Barber.fromJson(Map<String, dynamic> json) => Barber(
    id: jsonInt(json['id']),
    fullName: jsonString(json['fullName']),
    birthYear: jsonInt(json['birthYear']),
    branchId: jsonInt(json['branchId']),
    deletedAt: jsonDate(json['deletedAt']),
  );
}
