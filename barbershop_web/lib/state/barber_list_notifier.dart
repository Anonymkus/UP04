import '../models/barber.dart';
import '../models/barber_query.dart';
import '../repositories/barber_repository.dart';
import 'entity_list_notifier.dart';

class BarberListNotifier extends EntityListNotifier<Barber, BarberQuery> {
  BarberListNotifier(BarberRepository repository)
    : super(repository, const BarberQuery());
}
