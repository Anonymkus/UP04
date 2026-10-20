import 'query_params.dart';

class BarberQuery {
  static const sortFields = ['fullName', 'birthYear', 'id'];

  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BarberQuery({
    this.search = '',
    this.sortField = 'fullName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory BarberQuery.fromParams(Map<String, String> p) {
    final (sortField, sortAscending) = parseSort(p['sort'], sortFields);
    return BarberQuery(
      search: p['search'] ?? '',
      sortField: sortField,
      sortAscending: sortAscending,
      page: parsePage(p['page']),
      size: parseSize(p['size']),
      includeDeleted: p['deleted'] == 'true',
    );
  }

  Map<String, String> toParams() => {
    if (search.isNotEmpty) 'search': search,
    if (sortField != sortFields.first || !sortAscending)
      'sort': sortParam(sortField, sortAscending),
    if (page != 1) 'page': '$page',
    if (size != pageSizes.first) 'size': '$size',
    if (includeDeleted) 'deleted': 'true',
  };

  String get location => buildLocation('/barbers', toParams());

  BarberQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BarberQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BarberQuery && other.location == location;

  @override
  int get hashCode => location.hashCode;
}
