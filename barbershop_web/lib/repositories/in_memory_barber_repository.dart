import '../models/barber.dart';
import '../models/barber_query.dart';
import '../models/page_result.dart';
import 'barber_repository.dart';
import 'in_memory_repository.dart';
import 'seed_data.dart';

class InMemoryBarberRepository extends InMemoryRepository<Barber, BarberQuery>
    implements BarberRepository {
  InMemoryBarberRepository() : super(seedBarbers);

  @override
  Barber withId(Barber item, int id) => item.copyWith(id: id);

  @override
  Barber withDeletedAt(Barber item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);

  @override
  String notFound(int id) => 'Барбер $id не найден';

  @override
  Future<List<Barber>> all() async => List.unmodifiable(items);

  @override
  Future<PageResult<Barber>> find(BarberQuery q) async {
    await delay();
    var rows = items.where((b) => q.includeDeleted || !b.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) => b.fullName.toLowerCase().contains(needle))
          .toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        'id' => a.id.compareTo(b.id),
        _ => a.fullName.compareTo(b.fullName),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, q.page, q.size);
  }
}
