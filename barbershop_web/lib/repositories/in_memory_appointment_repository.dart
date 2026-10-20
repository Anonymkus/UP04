import '../models/appointment.dart';
import '../models/appointment_query.dart';
import '../models/page_result.dart';
import '../models/service.dart';
import 'appointment_repository.dart';
import 'in_memory_repository.dart';
import 'seed_data.dart';

class InMemoryAppointmentRepository
    extends InMemoryRepository<Appointment, AppointmentQuery>
    implements AppointmentRepository {
  InMemoryAppointmentRepository() : super(seedAppointments);

  @override
  Appointment withId(Appointment item, int id) => item.copyWith(id: id);

  @override
  Appointment withDeletedAt(Appointment item, DateTime? deletedAt) =>
      deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);

  @override
  String notFound(int id) => 'Запись $id не найдена';

  @override
  Future<List<Service>> services() async => seedServices;

  @override
  Future<PageResult<Appointment>> find(AppointmentQuery q) async {
    await delay();
    var rows = items.where((a) => q.includeDeleted || !a.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (a) =>
                a.clientName.toLowerCase().contains(needle) ||
                a.phone.contains(needle),
          )
          .toList();
    }
    if (q.serviceId != null) {
      rows = rows.where((a) => a.serviceId == q.serviceId).toList();
    }
    if (q.barberId != null) {
      rows = rows.where((a) => a.barberId == q.barberId).toList();
    }
    if (q.dateFrom != null) {
      rows = rows.where((a) => !a.date.isBefore(q.dateFrom!)).toList();
    }
    if (q.dateTo != null) {
      final end = q.dateTo!.add(const Duration(days: 1));
      rows = rows.where((a) => a.date.isBefore(end)).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'clientName' => a.clientName.compareTo(b.clientName),
        'price' => a.price.compareTo(b.price),
        _ => a.date.compareTo(b.date),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, q.page, q.size);
  }
}
