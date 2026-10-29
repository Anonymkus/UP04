import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
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

class ApiRepository<T extends Entity, Q extends ListQuery<Q>>
    implements EntityRepository<T, Q> {
  final Dio dio;
  final String path;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(Q query) filters;

  ApiRepository(this.dio, this.path, this.fromJson, {this.filters = _none});

  static Map<String, dynamic> _none(Object _) => const {};

  CancelToken? _findToken;
  Future<List<T>>? _cache;

  void clearCache() => _cache = null;

  T _parse(Response response) =>
      fromJson(response.data as Map<String, dynamic>);

  Map<String, dynamic> _body(T item) => item.toJson()
    ..remove('id')
    ..remove('deletedAt');

  Future<R> _mutate<R>(Future<R> Function() action) async {
    final result = await guard(action);
    _cache = null;
    return result;
  }

  @override
  Future<PageResult<T>> find(Q q) {
    _findToken?.cancel();
    final token = _findToken = CancelToken();
    return guard(() async {
      final response = await dio.get(
        path,
        cancelToken: token,
        queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.includeDeleted) 'includeDeleted': true,
          ...filters(q),
        },
      );
      final data = response.data as Map<String, dynamic>;
      return PageResult(
        items: [
          for (final e in data['items'] as List? ?? const [])
            if (e is Map<String, dynamic>) fromJson(e),
        ],
        page: jsonInt(data['page']),
        size: jsonInt(data['size']),
        total: jsonInt(data['total']),
      );
    }, retry: true);
  }

  @override
  Future<List<T>> all() => _cache ??= _fetchAll().catchError((Object e) {
    _cache = null;
    throw e;
  });

  Future<List<T>> _fetchAll() => guard(() async {
    final response = await dio.get(
      path,
      queryParameters: {'size': 100, 'includeDeleted': true},
    );
    final items = (response.data as Map<String, dynamic>)['items'] as List;
    return [
      for (final e in items)
        if (e is Map<String, dynamic>) fromJson(e),
    ];
  }, retry: true);

  @override
  Future<T?> findById(int id) async {
    try {
      return await guard(
        () async => _parse(
          await dio.get('$path/$id', queryParameters: {'includeDeleted': true}),
        ),
        retry: true,
      );
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<T> create(T item) =>
      _mutate(() async => _parse(await dio.post(path, data: _body(item))));

  @override
  Future<T> update(T item) => _mutate(
    () async => _parse(await dio.put('$path/${item.id}', data: _body(item))),
  );

  @override
  Future<void> softDelete(int id) => _mutate(() => dio.delete('$path/$id'));

  @override
  Future<void> hardDelete(int id) =>
      _mutate(() => dio.delete('$path/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) => _mutate(() => dio.post('$path/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => _mutate(() async {
    final response = await dio.post('$path/bulk-delete', data: {'ids': ids});
    return jsonInt((response.data as Map<String, dynamic>)['deleted']);
  });
}
