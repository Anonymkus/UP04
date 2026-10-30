import 'package:shared_preferences/shared_preferences.dart';

import '../models/common.dart';
import '../models/service.dart';
import 'repository.dart';
import 'seed_data.dart';

abstract interface class ServiceRepository
    implements EntityRepository<Service, SimpleQuery> {}

class PersistentServiceRepository
    extends PersistentRepository<Service, SimpleQuery>
    implements ServiceRepository {
  PersistentServiceRepository(SharedPreferences prefs)
    : super(prefs, 'services', seedServices);

  @override
  Service fromJson(Map<String, dynamic> json) => Service.fromJson(json);

  @override
  Map<String, dynamic> toJson(Service item) => item.toJson();

  @override
  Service withId(Service item, int id) => item.copyWith(id: id);

  @override
  Service withDeletedAt(Service item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);

  @override
  String notFound(int id) => 'Услуга $id не найдена';

  @override
  Future<PageResult<Service>> find(SimpleQuery q) async {
    await delay();
    return findSimple(
      q,
      searchText: (s) => s.name,
      sortKey: (s, field) => switch (field) {
        'price' => s.price,
        'duration' => s.duration,
        _ => s.name,
      },
    );
  }
}
