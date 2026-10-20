import 'entity.dart';

class Barber implements Entity {
  @override
  final int id;
  final String fullName;
  final int birthYear;
  @override
  final DateTime? deletedAt;

  const Barber({
    required this.id,
    required this.fullName,
    required this.birthYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Barber copyWith({
    int? id,
    String? fullName,
    int? birthYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Barber(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      birthYear: birthYear ?? this.birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
