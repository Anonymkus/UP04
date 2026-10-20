import 'query_params.dart';

class AppointmentQuery {
  static const sortFields = ['date', 'clientName', 'price'];

  final String search;
  final int? serviceId;
  final int? barberId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const AppointmentQuery({
    this.search = '',
    this.serviceId,
    this.barberId,
    this.dateFrom,
    this.dateTo,
    this.sortField = 'date',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory AppointmentQuery.fromParams(Map<String, String> p) {
    final (sortField, sortAscending) = parseSort(p['sort'], sortFields);
    return AppointmentQuery(
      search: p['search'] ?? '',
      serviceId: parseInt(p['serviceId']),
      barberId: parseInt(p['barberId']),
      dateFrom: parseDate(p['dateFrom']),
      dateTo: parseDate(p['dateTo']),
      sortField: sortField,
      sortAscending: sortAscending,
      page: parsePage(p['page']),
      size: parseSize(p['size']),
      includeDeleted: p['deleted'] == 'true',
    );
  }

  Map<String, String> toParams() => {
    if (search.isNotEmpty) 'search': search,
    if (serviceId != null) 'serviceId': '$serviceId',
    if (barberId != null) 'barberId': '$barberId',
    if (dateFrom != null) 'dateFrom': dateParam(dateFrom!),
    if (dateTo != null) 'dateTo': dateParam(dateTo!),
    if (sortField != sortFields.first || !sortAscending)
      'sort': sortParam(sortField, sortAscending),
    if (page != 1) 'page': '$page',
    if (size != pageSizes.first) 'size': '$size',
    if (includeDeleted) 'deleted': 'true',
  };

  String get location => buildLocation('/appointments', toParams());

  AppointmentQuery copyWith({
    String? search,
    Object? serviceId = _unset,
    Object? barberId = _unset,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AppointmentQuery(
      search: search ?? this.search,
      serviceId: serviceId == _unset ? this.serviceId : serviceId as int?,
      barberId: barberId == _unset ? this.barberId : barberId as int?,
      dateFrom: dateFrom == _unset ? this.dateFrom : dateFrom as DateTime?,
      dateTo: dateTo == _unset ? this.dateTo : dateTo as DateTime?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  @override
  bool operator ==(Object other) =>
      other is AppointmentQuery && other.location == location;

  @override
  int get hashCode => location.hashCode;
}
