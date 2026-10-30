import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/common.dart';

abstract interface class EntityRepository<T, Q> {
  Future<PageResult<T>> find(Q query);
  Future<List<T>> all();
  Future<T?> findById(int id);
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

const storageVersion = 2;
const _versionKey = 'barbershop_version';
final storageNotices = <String>[];

void checkStorageVersion(SharedPreferences prefs) {
  final saved = prefs.getInt(_versionKey);
  if (saved != null && saved != storageVersion) {
    for (final key in prefs.getKeys().where(
      (k) => k.startsWith('barbershop_'),
    )) {
      prefs.remove(key);
    }
    storageNotices.add(
      'Формат сохранённых данных изменился (версия $saved → $storageVersion). '
      'Данные сброшены к начальному набору.',
    );
  }
  prefs.setInt(_versionKey, storageVersion);
}

abstract class PersistentRepository<T extends Entity, Q>
    implements EntityRepository<T, Q> {
  final SharedPreferences _prefs;
  final String _key;
  List<T> items = [];
  int _nextId = 1;

  PersistentRepository(this._prefs, String name, List<T> seed)
    : _key = 'barbershop_$name' {
    _restore(name, seed);
  }

  void _restore(String name, List<T> seed) {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      items = [...seed];
      save();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        items = [for (final e in list) fromJson(e as Map<String, dynamic>)];
      } catch (_) {
        items = [...seed];
        save();
        storageNotices.add(
          'Сохранённые данные «$name» повреждены, восстановлен начальный набор.',
        );
      }
    }
    for (final e in items) {
      if (e.id >= _nextId) _nextId = e.id + 1;
    }
  }

  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T item);
  T withId(T item, int id);
  T withDeletedAt(T item, DateTime? deletedAt);
  String notFound(int id);

  Future<void> save() =>
      _prefs.setString(_key, jsonEncode(items.map(toJson).toList()));

  Future<void> delay() => Future.delayed(const Duration(milliseconds: 250));

  PageResult<T> paginate(List<T> rows, int page, int size) {
    final total = rows.length;
    final from = (page - 1) * size;
    final to = (from + size) > total ? total : (from + size);
    final pageItems = from >= total ? <T>[] : rows.sublist(from, to);
    return PageResult(items: pageItems, page: page, size: size, total: total);
  }

  PageResult<T> findSimple(
    SimpleQuery q, {
    required String Function(T item) searchText,
    required Comparable Function(T item, String field) sortKey,
  }) {
    var rows = items.where((e) => q.includeDeleted || e.deletedAt == null);
    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows.where((e) => searchText(e).toLowerCase().contains(needle));
    }
    final list = rows.toList()
      ..sort((a, b) {
        final result = sortKey(
          a,
          q.activeSortField,
        ).compareTo(sortKey(b, q.activeSortField));
        return q.sortAscending ? result : -result;
      });
    return paginate(list, q.page, q.size);
  }

  int _indexOf(int id) {
    final i = items.indexWhere((e) => e.id == id);
    if (i == -1) throw StateError(notFound(id));
    return i;
  }

  @override
  Future<List<T>> all() async => List.unmodifiable(items);

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
    await save();
    return created;
  }

  @override
  Future<T> update(T item) async {
    items[_indexOf(item.id)] = item;
    await save();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _indexOf(id);
    items[i] = withDeletedAt(items[i], DateTime.now());
    await save();
  }

  @override
  Future<void> hardDelete(int id) async {
    items.removeWhere((e) => e.id == id);
    await save();
  }

  @override
  Future<void> restore(int id) async {
    final i = _indexOf(id);
    items[i] = withDeletedAt(items[i], null);
    await save();
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
    await save();
    return count;
  }
}
