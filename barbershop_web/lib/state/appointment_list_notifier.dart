import '../models/appointment.dart';
import '../models/appointment_query.dart';
import '../models/barber.dart';
import '../models/service.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/barber_repository.dart';
import 'entity_list_notifier.dart';

class AppointmentListNotifier
    extends EntityListNotifier<Appointment, AppointmentQuery> {
  final AppointmentRepository _appointments;
  final BarberRepository _barbers;

  AppointmentListNotifier(this._appointments, this._barbers)
    : super(_appointments, const AppointmentQuery());

  List<Service> _services = [];
  List<Barber> _barberList = [];

  List<Service> get services => _services;
  List<Barber> get barbers => _barberList;

  Future<void> loadLookups() async {
    _services = await _appointments.services();
    _barberList = await _barbers.all();
    notifyListeners();
  }

  @override
  Future<void> load() async {
    _barberList = await _barbers.all();
    await super.load();
  }

  String serviceName(Appointment a) =>
      _services.where((s) => s.id == a.serviceId).map((s) => s.name).join();

  String barberName(Appointment a) => _barberList
      .where((b) => b.id == a.barberId)
      .map((b) => b.fullName)
      .join();
}
