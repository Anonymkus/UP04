import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/branch.dart';
import '../models/client.dart';
import '../models/common.dart';
import '../models/service.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/barber_repository.dart';
import '../repositories/branch_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/repository.dart';
import '../repositories/service_repository.dart';

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

  Future<String?> deleteBlocker(List<int> ids) async => null;

  Future<void> _checkDelete(List<int> ids) async {
    final message = await deleteBlocker(ids);
    if (message != null) throw StateError(message);
  }

  Future<int> deleteSelected() async {
    await _checkDelete(_selected.toList());
    final count = await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
    return count;
  }

  Future<void> softDelete(int id) async {
    await _checkDelete([id]);
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _checkDelete([id]);
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }

  Future<T?> findById(int id) => _repository.findById(id);

  Future<List<T>> all() => _repository.all();

  Future<void> save(T item) async {
    item.id == 0
        ? await _repository.create(item)
        : await _repository.update(item);
    version++;
    _status == LoadStatus.idle ? notifyListeners() : await load();
  }
}

class AppointmentListNotifier
    extends EntityListNotifier<Appointment, AppointmentQuery> {
  final ServiceRepository _services;
  final BarberRepository _barbers;
  final BranchRepository _branches;

  AppointmentListNotifier(
    AppointmentRepository repository,
    this._services,
    this._barbers,
    this._branches,
  ) : super(repository, const AppointmentQuery());

  List<Service> services = [];
  List<Barber> barbers = [];
  List<Branch> branches = [];

  Future<void> loadLookups() async {
    services = await _services.all();
    barbers = await _barbers.all();
    branches = await _branches.all();
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

  String barberName(Appointment a) =>
      barbers.where((b) => b.id == a.barberId).map((b) => b.fullName).join();

  Future<bool> isSlotTaken(int barberId, DateTime date, int exceptId) async =>
      (await all()).any(
        (a) =>
            a.id != exceptId &&
            a.deletedAt == null &&
            a.barberId == barberId &&
            a.date == date,
      );
}

class BarberListNotifier extends EntityListNotifier<Barber, SimpleQuery> {
  final BranchRepository _branches;

  BarberListNotifier(BarberRepository repository, this._branches)
    : super(repository, const SimpleQuery('/barbers', barberSort));

  static const barberSort = ['fullName', 'birthYear', 'id'];

  List<Branch> branches = [];

  Future<void> loadLookups() async {
    branches = await _branches.all();
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
  ServiceListNotifier(ServiceRepository repository)
    : super(repository, const SimpleQuery('/services', serviceSort));

  static const serviceSort = ['name', 'price', 'duration'];
}

class BranchListNotifier extends EntityListNotifier<Branch, SimpleQuery> {
  final BarberRepository _barbers;

  BranchListNotifier(BranchRepository repository, this._barbers)
    : super(repository, const SimpleQuery('/branches', branchSort));

  static const branchSort = ['name', 'address', 'id'];

  Future<List<Barber>> barbersOf(int branchId) async =>
      (await _barbers.all()).where((b) => b.branchId == branchId).toList();

  @override
  Future<String?> deleteBlocker(List<int> ids) async {
    final linked = (await _barbers.all())
        .where((b) => ids.contains(b.branchId))
        .length;
    if (linked == 0) return null;
    return 'Нельзя удалить филиал: к нему привязано барберов — $linked. '
        'Сначала переведите их в другой филиал.';
  }
}

class ClientListNotifier extends EntityListNotifier<Client, SimpleQuery> {
  ClientListNotifier(ClientRepository repository)
    : super(repository, const SimpleQuery('/clients', clientSort));

  static const clientSort = ['fullName', 'email', 'discount'];

  Future<bool> isEmailTaken(String email, int exceptId) async =>
      (await all()).any(
        (c) => c.id != exceptId && c.email.toLowerCase() == email.toLowerCase(),
      );

  Future<bool> isCardTaken(String number, int exceptId) async =>
      (await all()).any((c) => c.id != exceptId && c.card.number == number);
}
