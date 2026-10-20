import '../models/appointment.dart';
import '../models/appointment_query.dart';
import '../models/service.dart';
import 'entity_repository.dart';

abstract interface class AppointmentRepository
    implements EntityRepository<Appointment, AppointmentQuery> {
  Future<List<Service>> services();
}
