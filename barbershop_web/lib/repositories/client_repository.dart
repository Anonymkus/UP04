import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../models/common.dart';
import 'repository.dart';
import 'seed_data.dart';

abstract interface class ClientRepository
    implements EntityRepository<Client, SimpleQuery> {}

class PersistentClientRepository
    extends PersistentRepository<Client, SimpleQuery>
    implements ClientRepository {
  PersistentClientRepository(SharedPreferences prefs)
    : super(prefs, 'clients', seedClients);

  @override
  Client fromJson(Map<String, dynamic> json) => Client.fromJson(json);

  @override
  Map<String, dynamic> toJson(Client item) => item.toJson();

  @override
  Client withId(Client item, int id) => item.copyWith(id: id);

  @override
  Client withDeletedAt(Client item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);

  @override
  String notFound(int id) => 'Клиент $id не найден';

  @override
  Future<PageResult<Client>> find(SimpleQuery q) async {
    await delay();
    return findSimple(
      q,
      searchText: (c) => '${c.fullName} ${c.email} ${c.phone}',
      sortKey: (c, field) => switch (field) {
        'email' => c.email,
        'discount' => c.card.discount,
        _ => c.fullName,
      },
    );
  }
}
