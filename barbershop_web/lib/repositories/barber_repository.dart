import 'package:shared_preferences/shared_preferences.dart';

import '../models/barber.dart';
import '../models/common.dart';
import 'repository.dart';
import 'seed_data.dart';

abstract interface class BarberRepository
    implements EntityRepository<Barber, SimpleQuery> {}

class PersistentBarberRepository
    extends PersistentRepository<Barber, SimpleQuery>
    implements BarberRepository {
  PersistentBarberRepository(SharedPreferences prefs)
    : super(prefs, 'barbers', seedBarbers);

  @override
  Barber fromJson(Map<String, dynamic> json) => Barber.fromJson(json);

  @override
  Map<String, dynamic> toJson(Barber item) => item.toJson();

  @override
  Barber withId(Barber item, int id) => item.copyWith(id: id);

  @override
  Barber withDeletedAt(Barber item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);

  @override
  String notFound(int id) => 'Барбер $id не найден';

  @override
  Future<PageResult<Barber>> find(SimpleQuery q) async {
    await delay();
    return findSimple(
      q,
      searchText: (b) => b.fullName,
      sortKey: (b, field) => switch (field) {
        'birthYear' => b.birthYear,
        'id' => b.id,
        _ => b.fullName,
      },
    );
  }
}
