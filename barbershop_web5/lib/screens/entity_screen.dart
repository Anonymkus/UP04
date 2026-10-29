import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../models/common.dart';
import '../state/auth_notifier.dart';
import '../state/notifiers.dart';
import '../widgets/common.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';

class EntityListScreen<
  T extends Entity,
  Q extends ListQuery<Q>,
  N extends EntityListNotifier<T, Q>
>
    extends StatefulWidget {
  final String title;
  final String path;
  final Q query;
  final String searchLabel;
  final List<TableColumnSpec<T>> Function(N notifier) columns;
  final String Function(T item) nameOf;
  final List<Widget> Function(N notifier, void Function(Q next) go)? filters;

  const EntityListScreen({
    super.key,
    required this.title,
    required this.path,
    required this.query,
    required this.searchLabel,
    required this.columns,
    required this.nameOf,
    this.filters,
  });

  @override
  State<EntityListScreen<T, Q, N>> createState() =>
      _EntityListScreenState<T, Q, N>();
}

class _EntityListScreenState<
  T extends Entity,
  Q extends ListQuery<Q>,
  N extends EntityListNotifier<T, Q>
>
    extends State<EntityListScreen<T, Q, N>> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(EntityListScreen<T, Q, N> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _sync();
  }

  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<N>().applyQuery(widget.query);
    });
  }

  void _go(Q next) => context.go(next.location);

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<N>();
    final q = widget.query;
    final role = context.watch<AuthNotifier>().role;

    return AppScaffold(
      title: widget.title,
      body: EntityListView<T, Q>(
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
            ...?widget.filters?.call(notifier, _go),
            if (isAdmin(role))
              FilterChip(
                label: const Text('Показывать удалённые'),
                selected: q.includeDeleted,
                onSelected: (v) => _go(q.copyWith(includeDeleted: v)),
              ),
            TextButton(
              onPressed: () => _go(q.reset()),
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
        nameOf: widget.nameOf,
        pathOf: (item) => '${widget.path}/${item.id}',
        newPath: '${widget.path}/new',
        columns: widget.columns(notifier),
      ),
    );
  }
}

class EntityDetailScreen<
  T extends Entity,
  N extends EntityListNotifier<T, dynamic>
>
    extends StatefulWidget {
  final int id;
  final String title;
  final String backPath;
  final String notFoundText;
  final List<Widget> Function(BuildContext context, N notifier, T item) rows;

  const EntityDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.backPath,
    required this.notFoundText,
    required this.rows,
  });

  @override
  State<EntityDetailScreen<T, N>> createState() =>
      _EntityDetailScreenState<T, N>();
}

class _EntityDetailScreenState<
  T extends Entity,
  N extends EntityListNotifier<T, dynamic>
>
    extends State<EntityDetailScreen<T, N>> {
  Future<T?>? _future;
  int _version = -1;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<N>();
    final role = context.watch<AuthNotifier>().role;
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
          if (canManage(role))
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
