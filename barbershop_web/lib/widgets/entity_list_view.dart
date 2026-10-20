import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/entity.dart';
import '../state/entity_list_notifier.dart';
import 'confirm_dialog.dart';
import 'entity_table.dart';
import 'pagination_bar.dart';
import 'status_view.dart';

class EntityListView<T extends Entity, Q> extends StatelessWidget {
  final EntityListNotifier<T, Q> notifier;
  final Widget filters;
  final List<TableColumnSpec<T>> columns;
  final String sortField;
  final bool sortAscending;
  final int size;
  final void Function(String field) onSort;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;
  final String Function(T item) nameOf;
  final String Function(T item) pathOf;

  const EntityListView({
    super.key,
    required this.notifier,
    required this.filters,
    required this.columns,
    required this.sortField,
    required this.sortAscending,
    required this.size,
    required this.onSort,
    required this.onPage,
    required this.onSize,
    required this.nameOf,
    required this.pathOf,
  });

  Future<void> _deleteSelected(BuildContext context) async {
    final count = notifier.selected.length;
    if (!await confirm(context, 'Удалить выбранные записи ($count)?')) return;
    final deleted = await notifier.deleteSelected();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Удалено записей: $deleted')));
    }
  }

  Future<void> _softDelete(BuildContext context, T item) async {
    if (await confirm(context, 'Удалить «${nameOf(item)}»?')) {
      await notifier.softDelete(item.id);
    }
  }

  Future<void> _hardDelete(BuildContext context, T item) async {
    if (await confirm(
      context,
      'Удалить «${nameOf(item)}» безвозвратно? Отменить будет нельзя.',
    )) {
      await notifier.hardDelete(item.id);
    }
  }

  List<Widget> _actions(BuildContext context, T item) => [
    IconButton(
      tooltip: 'Открыть',
      icon: const Icon(Icons.visibility),
      onPressed: () => context.push(pathOf(item)),
    ),
    if (item.deletedAt == null)
      IconButton(
        tooltip: 'Удалить',
        icon: const Icon(Icons.delete),
        onPressed: () => _softDelete(context, item),
      )
    else
      IconButton(
        tooltip: 'Восстановить',
        icon: const Icon(Icons.restore),
        onPressed: () => notifier.restore(item.id),
      ),
    IconButton(
      tooltip: 'Удалить навсегда',
      icon: const Icon(Icons.delete_forever),
      onPressed: () => _hardDelete(context, item),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final result = notifier.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filters,
        const SizedBox(height: 8),
        if (notifier.hasSelection)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text('Выбрано: ${notifier.selected.length}'),
              TextButton(
                onPressed: notifier.clearSelection,
                child: const Text('Снять выделение'),
              ),
              FilledButton.icon(
                onPressed: () => _deleteSelected(context),
                icon: const Icon(Icons.delete),
                label: const Text('Удалить выбранные'),
              ),
            ],
          ),
        Expanded(
          child: StatusView(
            status: notifier.status,
            error: notifier.error,
            isEmpty: result.items.isEmpty,
            onRetry: notifier.load,
            child: EntityTable<T>(
              columns: columns,
              items: result.items,
              idOf: (e) => e.id,
              selected: notifier.selected,
              onToggleSelect: notifier.toggleSelection,
              sortField: sortField,
              sortAscending: sortAscending,
              onSort: onSort,
              actions: (item) => _actions(context, item),
              isMuted: (item) => item.deletedAt != null,
            ),
          ),
        ),
        PaginationBar(
          result: result,
          size: size,
          onPage: onPage,
          onSize: onSize,
        ),
      ],
    );
  }
}
