import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/branch.dart';
import '../models/client.dart';
import '../models/common.dart';
import '../models/service.dart';
import 'repository.dart';

class AppointmentRepository
    extends ApiRepository<Appointment, AppointmentQuery> {
  AppointmentRepository(super.dio, super.path, super.fromJson, {super.filters});

  Future<void> cancel(int id) => guard(() => dio.post('$path/$id/cancel'));
}

AppointmentRepository appointmentRepository(Dio dio) => AppointmentRepository(
  dio,
  '/appointments',
  Appointment.fromJson,
  filters: (q) => {
    if (q.serviceId != null) 'serviceId': q.serviceId,
    if (q.barberId != null) 'barberId': q.barberId,
    if (q.dateFrom != null) 'dateFrom': dateParam(q.dateFrom!),
    if (q.dateTo != null) 'dateTo': dateParam(q.dateTo!),
  },
);

ApiRepository<Barber, SimpleQuery> barberRepository(Dio dio) =>
    ApiRepository(dio, '/barbers', Barber.fromJson);

ApiRepository<Service, SimpleQuery> serviceRepository(Dio dio) =>
    ApiRepository(dio, '/services', Service.fromJson);

ApiRepository<Branch, SimpleQuery> branchRepository(Dio dio) =>
    ApiRepository(dio, '/branches', Branch.fromJson);

ApiRepository<Client, SimpleQuery> clientRepository(Dio dio) =>
    ApiRepository(dio, '/clients', Client.fromJson);
