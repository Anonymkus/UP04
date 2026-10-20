import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/barber.dart';
import '../models/barber_query.dart';
import '../state/barber_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/debounced_text_field.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';

class BarbersScreen extends StatefulWidget {
  final BarberQuery query;

  const BarbersScreen({super.key, required this.query});

  @override
  State<BarbersScreen> createState() => _BarbersScreenState();
}

class _BarbersScreenState extends State<BarbersScreen> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(BarbersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _sync();
  }

  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BarberListNotifier>().applyQuery(widget.query);
    });
  }

  void _go(BarberQuery next) => context.go(next.location);

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BarberListNotifier>();
    final q = widget.query;

    return AppScaffold(
      title: 'Барберы',
      body: EntityListView<Barber, BarberQuery>(
        notifier: notifier,
        filters: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DebouncedTextField(
              label: 'Поиск по ФИО',
              value: q.search,
              onChanged: (v) => _go(q.copyWith(search: v)),
            ),
            FilterChip(
              label: const Text('Показывать удалённые'),
              selected: q.includeDeleted,
              onSelected: (v) => _go(q.copyWith(includeDeleted: v)),
            ),
            TextButton(
              onPressed: () => _go(BarberQuery(size: q.size)),
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
        nameOf: (b) => b.fullName,
        pathOf: (b) => '/barbers/${b.id}',
        columns: [
          TableColumnSpec(
            label: '№',
            sortField: 'id',
            numeric: true,
            build: (b) => Text('${b.id}'),
          ),
          TableColumnSpec(
            label: 'ФИО',
            sortField: 'fullName',
            build: (b) => Text(b.fullName),
          ),
          TableColumnSpec(
            label: 'Год рождения',
            sortField: 'birthYear',
            numeric: true,
            build: (b) => Text('${b.birthYear}'),
          ),
        ],
      ),
    );
  }
}
