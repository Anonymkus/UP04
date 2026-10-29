import 'common.dart';

class Appointment implements Entity {
  @override
  final int id;
  final int clientId;
  final DateTime date;
  final List<int> serviceIds;
  final int price;
  final int barberId;
  @override
  final DateTime? deletedAt;

  const Appointment({
    required this.id,
    required this.clientId,
    required this.date,
    required this.serviceIds,
    required this.price,
    required this.barberId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Appointment copyWith({
    int? id,
    int? clientId,
    DateTime? date,
    List<int>? serviceIds,
    int? price,
    int? barberId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      serviceIds: serviceIds ?? this.serviceIds,
      price: price ?? this.price,
      barberId: barberId ?? this.barberId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Appointment withId(int id) => copyWith(id: id);

  @override
  Appointment withDeletedAt(DateTime? deletedAt) => deletedAt == null
      ? copyWith(clearDeletedAt: true)
      : copyWith(deletedAt: deletedAt);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'date': date.toIso8601String(),
    'serviceIds': serviceIds,
    'price': price,
    'barberId': barberId,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: jsonInt(json['id']),
    clientId: jsonRef(json, 'client'),
    date: jsonDate(json['date']) ?? DateTime(2000),
    serviceIds: jsonRefList(json, 'serviceIds', 'services'),
    price: jsonInt(json['price']),
    barberId: jsonRef(json, 'barber'),
    deletedAt: jsonDate(json['deletedAt']),
  );
}

class AppointmentQuery implements ListQuery<AppointmentQuery> {
  static const sortFields = ['date', 'clientName', 'price'];

  @override
  final String search;
  final int? serviceId;
  final int? barberId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  @override
  final String sortField;
  @override
  final bool sortAscending;
  @override
  final int page;
  @override
  final int size;
  @override
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

  @override
  String get location => buildLocation('/appointments', toParams());

  @override
  AppointmentQuery reset() => AppointmentQuery(size: size);

  @override
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
