import '../models/entity.dart';
import '../models/page_result.dart';
import 'entity_repository.dart';

abstract class InMemoryRepository<T extends Entity, Q>
    implements EntityRepository<T, Q> {
  final List<T> items;
  int _nextId;

  InMemoryRepository(List<T> seed)
    : items = [...seed],
      _nextId = seed.fold(0, (max, e) => e.id > max ? e.id : max) + 1;

  T withId(T item, int id);
  T withDeletedAt(T item, DateTime? deletedAt);
  String notFound(int id);

  Future<void> delay() => Future.delayed(const Duration(milliseconds: 250));

  PageResult<T> paginate(List<T> rows, int page, int size) {
    final total = rows.length;
    final from = (page - 1) * size;
    final to = (from + size) > total ? total : (from + size);
    final pageItems = from >= total ? <T>[] : rows.sublist(from, to);
    return PageResult(items: pageItems, page: page, size: size, total: total);
  }

  int _indexOf(int id) {
    final i = items.indexWhere((e) => e.id == id);
    if (i == -1) throw StateError(notFound(id));
    return i;
  }

  @override
  Future<T?> findById(int id) async {
    await delay();
    for (final e in items) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<T> create(T item) async {
    final created = withId(item, _nextId++);
    items.add(created);
    return created;
  }

  @override
  Future<T> update(T item) async {
    items[_indexOf(item.id)] = item;
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _indexOf(id);
    items[i] = withDeletedAt(items[i], DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _indexOf(id);
    items[i] = withDeletedAt(items[i], null);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = items.indexWhere((e) => e.id == id && e.deletedAt == null);
      if (i != -1) {
        items[i] = withDeletedAt(items[i], DateTime.now());
        count++;
      }
    }
    return count;
  }
}
