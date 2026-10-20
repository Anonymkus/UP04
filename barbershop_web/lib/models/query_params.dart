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

String sortParam(String field, bool ascending) =>
    '$field,${ascending ? 'asc' : 'desc'}';

String buildLocation(String path, Map<String, String> params) =>
    Uri(path: path, queryParameters: params.isEmpty ? null : params).toString();
