import 'entity.dart';

class Appointment implements Entity {
  @override
  final int id;
  final String clientName;
  final DateTime date;
  final String phone;
  final int serviceId;
  final int price;
  final int barberId;
  @override
  final DateTime? deletedAt;

  const Appointment({
    required this.id,
    required this.clientName,
    required this.date,
    required this.phone,
    required this.serviceId,
    required this.price,
    required this.barberId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Appointment copyWith({
    int? id,
    String? clientName,
    DateTime? date,
    String? phone,
    int? serviceId,
    int? price,
    int? barberId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      phone: phone ?? this.phone,
      serviceId: serviceId ?? this.serviceId,
      price: price ?? this.price,
      barberId: barberId ?? this.barberId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
