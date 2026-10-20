import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/appointment_query.dart';
import '../models/query_params.dart';
import '../state/appointment_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/debounced_text_field.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';

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
            label: 'Услуга',
            build: (a) => Text(notifier.serviceName(a)),
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
