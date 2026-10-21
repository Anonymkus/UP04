import 'package:shared_preferences/shared_preferences.dart';

import '../models/branch.dart';
import '../models/common.dart';
import 'repository.dart';
import 'seed_data.dart';

abstract interface class BranchRepository
    implements EntityRepository<Branch, SimpleQuery> {}

class PersistentBranchRepository
    extends PersistentRepository<Branch, SimpleQuery>
    implements BranchRepository {
  PersistentBranchRepository(SharedPreferences prefs)
    : super(prefs, 'branches', seedBranches);

  @override
  Branch fromJson(Map<String, dynamic> json) => Branch.fromJson(json);

  @override
  Map<String, dynamic> toJson(Branch item) => item.toJson();

  @override
  Branch withId(Branch item, int id) => item.copyWith(id: id);

  @override
  Branch withDeletedAt(Branch item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);

  @override
  String notFound(int id) => 'Филиал $id не найден';

  @override
  Future<PageResult<Branch>> find(SimpleQuery q) async {
    await delay();
    return findSimple(
      q,
      searchText: (b) => '${b.name} ${b.address}',
      sortKey: (b, field) => switch (field) {
        'address' => b.address,
        'id' => b.id,
        _ => b.name,
      },
    );
  }
}
