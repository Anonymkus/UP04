import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/common.dart';
import '../state/notifiers.dart';
import '../validators.dart';
import '../widgets/common.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';
import 'simple_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final AppointmentQuery query;

  const AppointmentsScreen({super.key, required this.query});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(AppointmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _sync();
  }

  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppointmentListNotifier>().applyQuery(widget.query);
      }
    });
  }

  void _go(AppointmentQuery next) => context.go(next.location);

  void _goDate(String text, AppointmentQuery Function(DateTime?) apply) {
    if (text.isEmpty) return _go(apply(null));
    final date = parseUserDate(text);
    if (date != null) _go(apply(date));
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AppointmentListNotifier>();
    final q = widget.query;
    final serviceId = notifier.services.any((s) => s.id == q.serviceId)
        ? q.serviceId
        : null;
    final barberId = notifier.barbers.any((b) => b.id == q.barberId)
        ? q.barberId
        : null;

    return AppScaffold(
      title: 'Записи клиентов',
      body: EntityListView<Appointment, AppointmentQuery>(
        notifier: notifier,
        filters: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DebouncedTextField(
              label: 'Поиск по ФИО или телефону',
              value: q.search,
              onChanged: (v) => _go(q.copyWith(search: v)),
            ),
            DropdownButton<int?>(
              value: serviceId,
              hint: const Text('Все услуги'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Все услуги')),
                for (final s in notifier.services)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => _go(q.copyWith(serviceId: v)),
            ),
            DropdownButton<int?>(
              value: barberId,
              hint: const Text('Все барберы'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Все барберы')),
                for (final b in notifier.barbers)
                  DropdownMenuItem(value: b.id, child: Text(b.fullName)),
              ],
              onChanged: (v) => _go(q.copyWith(barberId: v)),
            ),
            DebouncedTextField(
              label: 'Дата с (ДД.ММ.ГГГГ)',
              width: 180,
              value: q.dateFrom == null ? '' : formatDate(q.dateFrom!),
              onChanged: (v) => _goDate(v, (d) => q.copyWith(dateFrom: d)),
            ),
            DebouncedTextField(
              label: 'Дата по (ДД.ММ.ГГГГ)',
              width: 180,
              value: q.dateTo == null ? '' : formatDate(q.dateTo!),
              onChanged: (v) => _goDate(v, (d) => q.copyWith(dateTo: d)),
            ),
            FilterChip(
              label: const Text('Показывать удалённые'),
              selected: q.includeDeleted,
              onSelected: (v) => _go(q.copyWith(includeDeleted: v)),
            ),
            TextButton(
              onPressed: () => _go(AppointmentQuery(size: q.size)),
              child: const Text('Сбросить'),
            ),
          ],
        ),
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        size: q.size,
        onSort: (field) => _go(
          q.copyWith(
            sortField: field,
            sortAscending: field == q.sortField ? !q.sortAscending : true,
          ),
        ),
        onPage: (page) => _go(q.copyWith(page: page)),
        onSize: (size) => _go(q.copyWith(size: size)),
        nameOf: (a) => '${a.clientName}, ${formatDateTime(a.date)}',
        pathOf: (a) => '/appointments/${a.id}',
        newPath: '/appointments/new',
        columns: [
          TableColumnSpec(
            label: 'ФИО клиента',
            sortField: 'clientName',
            build: (a) => Text(a.clientName),
          ),
          TableColumnSpec(
            label: 'Дата',
            sortField: 'date',
            build: (a) => Text(formatDateTime(a.date)),
          ),
          TableColumnSpec(label: 'Телефон', build: (a) => Text(a.phone)),
          TableColumnSpec(
            label: 'Услуги',
            build: (a) => Text(notifier.serviceNames(a)),
          ),
          TableColumnSpec(
            label: 'Стоимость',
            sortField: 'price',
            numeric: true,
            build: (a) => Text('${a.price} ₽'),
          ),
          TableColumnSpec(
            label: 'Барбер',
            build: (a) => Text(notifier.barberName(a)),
          ),
        ],
      ),
    );
  }
}

Widget appointmentDetail(int id) =>
    SimpleDetailScreen<Appointment, AppointmentListNotifier>(
      id: id,
      title: 'Карточка записи',
      backPath: '/appointments',
      notFoundText: 'Запись $id не найдена',
      rows: (context, n, a) => [
        Text(a.clientName, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        DetailRow.text('Дата и время', formatDateTime(a.date)),
        DetailRow.text('Телефон', a.phone),
        DetailRow.text('Услуги', n.serviceNames(a)),
        DetailRow.text('Стоимость', '${a.price} ₽'),
        DetailRow(
          'Барбер',
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              label: Text(n.barberName(a)),
              onPressed: () => context.push('/barbers/${a.barberId}'),
            ),
          ),
        ),
      ],
    );

class AppointmentFormScreen extends StatefulWidget {
  final int? id;

  const AppointmentFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _clientName = TextEditingController();
  final _phone = TextEditingController();
  final _date = TextEditingController();
  final _price = TextEditingController();
  int? _branchId;
  int? _barberId;
  List<int> _serviceIds = [];
  Appointment? _original;
  bool _loading = false;
  String? _notFound;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loading = true;
      final notifier = context.read<AppointmentListNotifier>();
      notifier.findById(widget.id!).then((a) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          if (a == null) {
            _notFound = 'Запись ${widget.id} не найдена';
            return;
          }
          _original = a;
          _clientName.text = a.clientName;
          _phone.text = a.phone;
          _date.text = formatDateTime(a.date);
          _price.text = '${a.price}';
          _serviceIds = a.serviceIds;
          _barberId = a.barberId;
          _branchId = notifier.barbers
              .where((b) => b.id == a.barberId)
              .map((b) => b.branchId)
              .firstOrNull;
        });
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_clientName, _phone, _date, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  void _updatePrice(AppointmentListNotifier notifier, List<int> ids) {
    _serviceIds = ids;
    final sum = notifier.services
        .where((s) => ids.contains(s.id))
        .fold(0, (total, s) => total + s.price);
    _price.text = sum == 0 ? '' : '$sum';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AppointmentListNotifier>();
    final branches = notifier.branches.where(
      (b) => b.deletedAt == null || b.id == _branchId,
    );
    final barbers = notifier.barbers.where(
      (b) =>
          b.branchId == _branchId && (b.deletedAt == null || b.id == _barberId),
    );
    final services = notifier.services.where(
      (s) => s.deletedAt == null || _serviceIds.contains(s.id),
    );

    return EntityForm(
      title: widget.isEditing ? 'Изменение записи' : 'Новая запись',
      backPath: '/appointments',
      loading: _loading,
      notFound: _notFound,
      fields: (errors) => [
        TextFieldSpec(
          label: 'ФИО клиента',
          controller: _clientName,
          validator: all([notEmpty, minLength(5), maxLength(100)]),
        ),
        TextFieldSpec(
          label: 'Телефон',
          controller: _phone,
          hint: '+7 999 123 45 67',
          validator: all([notEmpty, phone]),
        ),
        TextFieldSpec(
          label: 'Дата и время',
          controller: _date,
          hint: 'ДД.ММ.ГГГГ ЧЧ:ММ',
          validator: all([notEmpty, dateTime, serverError(errors, 'date')]),
        ),
        DropdownButtonFormField<int>(
          initialValue: branches.any((b) => b.id == _branchId)
              ? _branchId
              : null,
          decoration: const InputDecoration(
            labelText: 'Филиал',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final b in branches)
              DropdownMenuItem(value: b.id, child: Text(b.name)),
          ],
          onChanged: (v) => setState(() {
            _branchId = v;
            _barberId = null;
          }),
          validator: (v) => v == null ? 'Выберите филиал' : null,
        ),
        DropdownButtonFormField<int>(
          key: ValueKey(_branchId),
          initialValue: barbers.any((b) => b.id == _barberId)
              ? _barberId
              : null,
          decoration: InputDecoration(
            labelText: 'Барбер',
            helperText: _branchId == null ? 'Сначала выберите филиал' : null,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final b in barbers)
              DropdownMenuItem(value: b.id, child: Text(b.fullName)),
          ],
          onChanged: (v) => _barberId = v,
          validator: (v) => v == null ? 'Выберите барбера' : null,
        ),
        MultiSelectField(
          label: 'Услуги',
          options: [
            for (final s in services) (s.id, '${s.name}, ${s.price} ₽'),
          ],
          initialValue: _serviceIds,
          onChanged: (ids) => setState(() => _updatePrice(notifier, ids)),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Выберите хотя бы одну услугу' : null,
        ),
        TextFieldSpec(
          label: 'Стоимость, ₽',
          controller: _price,
          number: true,
          validator: all([notEmpty, positiveInt, intRange(1, 100000)]),
        ),
      ],
      onSave: () async {
        final id = widget.id ?? 0;
        final date = parseUserDateTime(_date.text)!;
        if (await notifier.isSlotTaken(_barberId!, date, id)) {
          return {'date': 'Барбер уже занят в это время'};
        }
        await notifier.save(
          Appointment(
            id: id,
            clientName: _clientName.text.trim(),
            date: date,
            phone: _phone.text.trim(),
            serviceIds: _serviceIds,
            price: int.parse(_price.text.trim()),
            barberId: _barberId!,
            deletedAt: _original?.deletedAt,
          ),
        );
        return {};
      },
    );
  }
}
