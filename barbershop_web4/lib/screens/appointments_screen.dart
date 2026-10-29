import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/common.dart';
import '../state/notifiers.dart';
import '../validators.dart';
import '../widgets/common.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import 'entity_screen.dart';

Widget appointmentsList(Map<String, String> params) =>
    EntityListScreen<Appointment, AppointmentQuery, AppointmentListNotifier>(
      title: 'Записи клиентов',
      path: '/appointments',
      query: AppointmentQuery.fromParams(params),
      searchLabel: 'Поиск по ФИО или телефону',
      nameOf: (a) => 'запись №${a.id} от ${formatDateTime(a.date)}',
      filters: (n, go) {
        final q = AppointmentQuery.fromParams(params);
        void goDate(String text, AppointmentQuery Function(DateTime?) apply) {
          if (text.isEmpty) return go(apply(null));
          final date = parseUserDate(text);
          if (date != null) go(apply(date));
        }

        return [
          DropdownButton<int?>(
            value: n.services.any((s) => s.id == q.serviceId)
                ? q.serviceId
                : null,
            hint: const Text('Все услуги'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Все услуги')),
              for (final s in n.services)
                DropdownMenuItem(value: s.id, child: Text(s.name)),
            ],
            onChanged: (v) => go(q.copyWith(serviceId: v)),
          ),
          DropdownButton<int?>(
            value: n.barbers.any((b) => b.id == q.barberId) ? q.barberId : null,
            hint: const Text('Все барберы'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Все барберы')),
              for (final b in n.barbers)
                DropdownMenuItem(value: b.id, child: Text(b.fullName)),
            ],
            onChanged: (v) => go(q.copyWith(barberId: v)),
          ),
          DebouncedTextField(
            label: 'Дата с (ДД.ММ.ГГГГ)',
            width: 180,
            value: q.dateFrom == null ? '' : formatDate(q.dateFrom!),
            onChanged: (v) => goDate(v, (d) => q.copyWith(dateFrom: d)),
          ),
          DebouncedTextField(
            label: 'Дата по (ДД.ММ.ГГГГ)',
            width: 180,
            value: q.dateTo == null ? '' : formatDate(q.dateTo!),
            onChanged: (v) => goDate(v, (d) => q.copyWith(dateTo: d)),
          ),
        ];
      },
      columns: (n) => [
        TableColumnSpec(
          label: 'ФИО клиента',
          sortField: 'clientName',
          build: (a) => Text(n.clientName(a)),
        ),
        TableColumnSpec(
          label: 'Дата',
          sortField: 'date',
          build: (a) => Text(formatDateTime(a.date)),
        ),
        TableColumnSpec(label: 'Телефон', build: (a) => Text(n.clientPhone(a))),
        TableColumnSpec(label: 'Услуги', build: (a) => Text(n.serviceNames(a))),
        TableColumnSpec(
          label: 'Стоимость',
          sortField: 'price',
          numeric: true,
          build: (a) => Text('${a.price} ₽'),
        ),
        TableColumnSpec(label: 'Барбер', build: (a) => Text(n.barberName(a))),
      ],
    );

Widget appointmentDetail(int id) =>
    EntityDetailScreen<Appointment, AppointmentListNotifier>(
      id: id,
      title: 'Карточка записи',
      backPath: '/appointments',
      notFoundText: 'Запись $id не найдена',
      rows: (context, n, a) => [
        Text(
          'Запись №${a.id}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        DetailRow(
          'Клиент',
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              label: Text(n.clientName(a)),
              onPressed: () => context.push('/clients/${a.clientId}'),
            ),
          ),
        ),
        DetailRow.text('Телефон', n.clientPhone(a)),
        DetailRow.text('Дата и время', formatDateTime(a.date)),
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
  final _date = TextEditingController();
  final _price = TextEditingController();
  int? _clientId;
  int? _branchId;
  int? _barberId;
  List<int> _serviceIds = [];
  Appointment? _original;

  @override
  void dispose() {
    for (final c in [_date, _price]) {
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
    final clients = notifier.clients.where(
      (c) => c.deletedAt == null || c.id == _clientId,
    );
    final services = notifier.services.where(
      (s) => s.deletedAt == null || _serviceIds.contains(s.id),
    );

    return EntityForm<Appointment>(
      title: widget.isEditing ? 'Изменение записи' : 'Новая запись',
      backPath: '/appointments',
      load: widget.id == null ? null : () => notifier.findById(widget.id!),
      onLoaded: (a) {
        _original = a;
        _clientId = a.clientId;
        _date.text = formatDateTime(a.date);
        _price.text = '${a.price}';
        _serviceIds = a.serviceIds;
        _barberId = a.barberId;
        _branchId = notifier.barbers
            .where((b) => b.id == a.barberId)
            .map((b) => b.branchId)
            .firstOrNull;
      },
      fields: (errors) => [
        DropdownButtonFormField<int>(
          initialValue: clients.any((c) => c.id == _clientId)
              ? _clientId
              : null,
          decoration: const InputDecoration(
            labelText: 'Клиент',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final c in clients)
              DropdownMenuItem(
                value: c.id,
                child: Text('${c.fullName}, ${c.phone}'),
              ),
          ],
          onChanged: (v) => _clientId = v,
          validator: (v) => v == null ? 'Выберите клиента' : null,
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
        await notifier.save(
          Appointment(
            id: id,
            clientId: _clientId!,
            date: date,
            serviceIds: _serviceIds,
            price: int.parse(_price.text.trim()),
            barberId: _barberId!,
            deletedAt: _original?.deletedAt,
          ),
        );
      },
    );
  }
}
