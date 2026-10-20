import '../models/barber.dart';
import '../models/barber_query.dart';
import 'entity_repository.dart';

abstract interface class BarberRepository
    implements EntityRepository<Barber, BarberQuery> {
  Future<List<Barber>> all();
}
