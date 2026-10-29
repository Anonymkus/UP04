abstract interface class Entity {
  int get id;
  DateTime? get deletedAt;
}

class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;

  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  int get totalPages => total == 0 ? 1 : (total / size).ceil();
  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  PageResult.empty() : items = <T>[], page = 1, size = 10, total = 0;
}

const pageSizes = [10, 25, 50];

int? parseInt(String? value) => value == null ? null : int.tryParse(value);

int parsePage(String? value) {
  final page = parseInt(value) ?? 1;
  return page < 1 ? 1 : page;
}

int parseSize(String? value) {
  final size = parseInt(value);
  return pageSizes.contains(size) ? size! : pageSizes.first;
}

(String, bool) parseSort(String? value, List<String> fields) {
  final parts = (value ?? '').split(',');
  final field = fields.contains(parts.first) ? parts.first : fields.first;
  final ascending = parts.length < 2 || parts[1] != 'desc';
  return (field, ascending);
}

String _two(int v) => v.toString().padLeft(2, '0');

DateTime? parseDate(String? value) {
  final d = value == null ? null : DateTime.tryParse(value);
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

String dateParam(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

String formatDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

String formatDateTime(DateTime d) =>
    '${formatDate(d)} ${_two(d.hour)}:${_two(d.minute)}';

DateTime? parseUserDate(String value) {
  final parts = value.trim().split('.');
  if (parts.length != 3 || parts[2].length != 4) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}

DateTime? parseUserDateTime(String value) {
  final parts = value.trim().split(' ');
  if (parts.length != 2) return null;
  final date = parseUserDate(parts[0]);
  final time = parts[1].split(':');
  if (date == null || time.length != 2) return null;
  final hour = int.tryParse(time[0]);
  final minute = int.tryParse(time[1]);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

String sortParam(String field, bool ascending) =>
    '$field,${ascending ? 'asc' : 'desc'}';

String buildLocation(String path, Map<String, String> params) =>
    Uri(path: path, queryParameters: params.isEmpty ? null : params).toString();

int jsonInt(Object? value) => value is int ? value : 0;

String jsonString(Object? value) => value is String ? value : '';

DateTime? jsonDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

List<int> jsonIntList(Object? value) =>
    value is List ? value.whereType<int>().toList() : const [];

class SimpleQuery {
  final String path;
  final List<String> sortFields;
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const SimpleQuery(
    this.path,
    this.sortFields, {
    this.search = '',
    String? sortField,
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  }) : sortField = sortField ?? '';

  String get activeSortField =>
      sortField.isEmpty ? sortFields.first : sortField;

  factory SimpleQuery.fromParams(
    String path,
    List<String> sortFields,
    Map<String, String> p,
  ) {
    final (sortField, sortAscending) = parseSort(p['sort'], sortFields);
    return SimpleQuery(
      path,
      sortFields,
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
    if (activeSortField != sortFields.first || !sortAscending)
      'sort': sortParam(activeSortField, sortAscending),
    if (page != 1) 'page': '$page',
    if (size != pageSizes.first) 'size': '$size',
    if (includeDeleted) 'deleted': 'true',
  };

  String get location => buildLocation(path, toParams());

  SimpleQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return SimpleQuery(
      path,
      sortFields,
      search: search ?? this.search,
      sortField: sortField ?? activeSortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SimpleQuery && other.location == location;

  @override
  int get hashCode => location.hashCode;
}
