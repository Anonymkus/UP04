import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/branch.dart';
import '../models/client.dart';
import '../models/common.dart';
import '../models/service.dart';
import '../models/user.dart';
import '../repositories/auth_api.dart';
import '../repositories/repositories.dart';
import '../repositories/repository.dart';

enum LoadStatus { idle, loading, success, error }

class EntityListNotifier<T extends Entity, Q> extends ChangeNotifier {
  final EntityRepository<T, Q> _repository;

  EntityListNotifier(this._repository, Q initialQuery) : _query = initialQuery;

  Q _query;
  PageResult<T> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  int _request = 0;
  int version = 0;

  Q get query => _query;
  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    final request = ++_request;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.find(_query);
      if (request != _request) return;
      _result = result;
      _status = LoadStatus.success;
    } catch (e) {
      if (request != _request) return;
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _request++;
    _result = PageResult.empty();
    _status = LoadStatus.idle;
    _selected.clear();
    version++;
  }

  Future<void> applyQuery(Q next) async {
    if (next == _query && _status != LoadStatus.idle) return;
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<int> deleteSelected() async {
    final count = await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
    return count;
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }

  Future<T?> findById(int id) => _repository.findById(id);

  Future<void> save(T item) async {
    item.id == 0
        ? await _repository.create(item)
        : await _repository.update(item);
    version++;
    _status == LoadStatus.idle ? notifyListeners() : await load();
  }
}

Future<List<X>> _safe<X>(Future<List<X>> Function() load) async {
  try {
    return await load();
  } on ApiException {
    return [];
  }
}

class AppointmentListNotifier
    extends EntityListNotifier<Appointment, AppointmentQuery> {
  final EntityRepository<Service, SimpleQuery> _services;
  final EntityRepository<Barber, SimpleQuery> _barbers;
  final EntityRepository<Branch, SimpleQuery> _branches;
  final EntityRepository<Client, SimpleQuery> _clients;

  AppointmentListNotifier(
    EntityRepository<Appointment, AppointmentQuery> repository,
    this._services,
    this._barbers,
    this._branches,
    this._clients,
  ) : super(repository, const AppointmentQuery());

  List<Service> services = [];
  List<Barber> barbers = [];
  List<Branch> branches = [];
  List<Client> clients = [];

  Future<void> loadLookups() async {
    services = await _safe(_services.all);
    barbers = await _safe(_barbers.all);
    branches = await _safe(_branches.all);
    clients = await _safe(_clients.all);
    notifyListeners();
  }

  @override
  Future<void> load() async {
    await loadLookups();
    await super.load();
  }

  String serviceNames(Appointment a) => services
      .where((s) => a.serviceIds.contains(s.id))
      .map((s) => s.name)
      .join(', ');

  Client? clientOf(Appointment a) =>
      clients.where((c) => c.id == a.clientId).firstOrNull;

  String clientName(Appointment a) => clientOf(a)?.fullName ?? '';

  String clientPhone(Appointment a) => clientOf(a)?.phone ?? '';

  String barberName(Appointment a) =>
      barbers.where((b) => b.id == a.barberId).map((b) => b.fullName).join();
}

class BarberListNotifier extends EntityListNotifier<Barber, SimpleQuery> {
  final EntityRepository<Branch, SimpleQuery> _branches;

  BarberListNotifier(
    EntityRepository<Barber, SimpleQuery> repository,
    this._branches,
  ) : super(repository, SimpleQuery('/barbers', barberSort));

  static const barberSort = ['fullName', 'birthYear', 'id'];

  List<Branch> branches = [];

  Future<void> loadLookups() async {
    branches = await _safe(_branches.all);
    notifyListeners();
  }

  @override
  Future<void> load() async {
    await loadLookups();
    await super.load();
  }

  String branchName(Barber b) =>
      branches.where((x) => x.id == b.branchId).map((x) => x.name).join();
}

class ServiceListNotifier extends EntityListNotifier<Service, SimpleQuery> {
  ServiceListNotifier(EntityRepository<Service, SimpleQuery> repository)
    : super(repository, SimpleQuery('/services', serviceSort));

  static const serviceSort = ['name', 'price', 'duration'];
}

class BranchListNotifier extends EntityListNotifier<Branch, SimpleQuery> {
  final EntityRepository<Barber, SimpleQuery> _barbers;

  BranchListNotifier(
    EntityRepository<Branch, SimpleQuery> repository,
    this._barbers,
  ) : super(repository, SimpleQuery('/branches', branchSort));

  static const branchSort = ['name', 'address', 'id'];

  Future<List<Barber>> barbersOf(int branchId) async =>
      (await _barbers.all()).where((b) => b.branchId == branchId).toList();
}

class ClientListNotifier extends EntityListNotifier<Client, SimpleQuery> {
  ClientListNotifier(EntityRepository<Client, SimpleQuery> repository)
    : super(repository, SimpleQuery('/clients', clientSort));

  static const clientSort = ['fullName', 'email', 'discount'];
}

class MyAppointmentsNotifier extends ChangeNotifier {
  final AppointmentRepository _appointments;
  final EntityRepository<Service, SimpleQuery> _services;
  final EntityRepository<Barber, SimpleQuery> _barbers;

  MyAppointmentsNotifier(this._appointments, this._services, this._barbers);

  List<Appointment> items = [];
  List<Service> services = [];
  List<Barber> barbers = [];
  LoadStatus status = LoadStatus.idle;
  String? error;

  Future<void> load() async {
    status = LoadStatus.loading;
    notifyListeners();
    try {
      services = await _services.all();
      barbers = await _barbers.all();
      final page = await _appointments.find(
        const AppointmentQuery(size: 50, sortField: 'date'),
      );
      items = page.items;
      status = LoadStatus.success;
    } on ApiException catch (e) {
      error = e.message;
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> cancel(int id) async {
    await _appointments.cancel(id);
    await load();
  }

  String serviceNames(Appointment a) => services
      .where((s) => a.serviceIds.contains(s.id))
      .map((s) => s.name)
      .join(', ');

  String barberName(Appointment a) =>
      barbers.where((b) => b.id == a.barberId).map((b) => b.fullName).join();
}

class AdminNotifier extends ChangeNotifier {
  final AdminApi _api;

  AdminNotifier(this._api);

  List<AppUser> users = [];
  Map<String, dynamic> stats = {};
  LoadStatus status = LoadStatus.idle;
  String? error;

  Future<void> _run(Future<void> Function() action) async {
    status = LoadStatus.loading;
    notifyListeners();
    try {
      await action();
      status = LoadStatus.success;
    } on ApiException catch (e) {
      error = e.message;
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadUsers() => _run(() async => users = await _api.users());

  Future<void> loadStats() => _run(() async => stats = await _api.stats());

  Future<void> setRole(AppUser user, Role role) async {
    await _api.setRole(user.id, role);
    await loadUsers();
  }
}
