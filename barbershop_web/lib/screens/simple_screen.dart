import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/common.dart';
import '../state/notifiers.dart';
import '../widgets/common.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';

class SimpleListScreen<
  T extends Entity,
  N extends EntityListNotifier<T, SimpleQuery>
>
    extends StatefulWidget {
  final String title;
  final SimpleQuery query;
  final String searchLabel;
  final List<TableColumnSpec<T>> Function(N notifier) columns;
  final String Function(T item) nameOf;

  const SimpleListScreen({
    super.key,
    required this.title,
    required this.query,
    required this.searchLabel,
    required this.columns,
    required this.nameOf,
  });

  @override
  State<SimpleListScreen<T, N>> createState() => _SimpleListScreenState<T, N>();
}

class _SimpleListScreenState<
  T extends Entity,
  N extends EntityListNotifier<T, SimpleQuery>
>
    extends State<SimpleListScreen<T, N>> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SimpleListScreen<T, N> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _sync();
  }

  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<N>().applyQuery(widget.query);
    });
  }

  void _go(SimpleQuery next) => context.go(next.location);

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<N>();
    final q = widget.query;

    return AppScaffold(
      title: widget.title,
      body: EntityListView<T, SimpleQuery>(
        notifier: notifier,
        filters: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DebouncedTextField(
              label: widget.searchLabel,
              value: q.search,
              onChanged: (v) => _go(q.copyWith(search: v)),
            ),
            FilterChip(
              label: const Text('Показывать удалённые'),
              selected: q.includeDeleted,
              onSelected: (v) => _go(q.copyWith(includeDeleted: v)),
            ),
            TextButton(
              onPressed: () =>
                  _go(SimpleQuery(q.path, q.sortFields, size: q.size)),
              child: const Text('Сбросить'),
            ),
          ],
        ),
        sortField: q.activeSortField,
        sortAscending: q.sortAscending,
        size: q.size,
        onSort: (field) => _go(
          q.copyWith(
            sortField: field,
            sortAscending: field == q.activeSortField ? !q.sortAscending : true,
          ),
        ),
        onPage: (page) => _go(q.copyWith(page: page)),
        onSize: (size) => _go(q.copyWith(size: size)),
        nameOf: widget.nameOf,
        pathOf: (item) => '${q.path}/${item.id}',
        newPath: '${q.path}/new',
        columns: widget.columns(notifier),
      ),
    );
  }
}

class SimpleDetailScreen<
  T extends Entity,
  N extends EntityListNotifier<T, dynamic>
>
    extends StatefulWidget {
  final int id;
  final String title;
  final String backPath;
  final String notFoundText;
  final List<Widget> Function(BuildContext context, N notifier, T item) rows;

  const SimpleDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.backPath,
    required this.notFoundText,
    required this.rows,
  });

  @override
  State<SimpleDetailScreen<T, N>> createState() =>
      _SimpleDetailScreenState<T, N>();
}

class _SimpleDetailScreenState<
  T extends Entity,
  N extends EntityListNotifier<T, dynamic>
>
    extends State<SimpleDetailScreen<T, N>> {
  Future<T?>? _future;
  int _version = -1;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<N>();
    if (notifier.version != _version) {
      _version = notifier.version;
      _future = notifier.findById(widget.id);
    }
    return AppScaffold(
      title: widget.title,
      backPath: widget.backPath,
      body: DetailView<T>(
        future: _future!,
        notFoundText: widget.notFoundText,
        builder: (item) => [
          ...widget.rows(context, notifier, item),
          if (item.deletedAt != null)
            DetailRow.text('Удалено', formatDateTime(item.deletedAt!)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () =>
                  context.push('${widget.backPath}/${widget.id}/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('Изменить'),
            ),
          ),
        ],
      ),
    );
  }
}
