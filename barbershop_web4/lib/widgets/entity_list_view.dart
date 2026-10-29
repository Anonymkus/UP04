import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../models/common.dart';
import '../state/notifiers.dart';
import 'entity_table.dart';

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
  final String newPath;

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
    required this.newPath,
  });

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final count = notifier.selected.length;
    if (!await confirm(context, 'Удалить выбранные записи ($count)?')) return;
    if (!context.mounted) return;
    await _run(context, () async {
      final deleted = await notifier.deleteSelected();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Удалено записей: $deleted')));
      }
    });
  }

  Future<void> _softDelete(BuildContext context, T item) async {
    if (await confirm(context, 'Удалить «${nameOf(item)}»?') &&
        context.mounted) {
      await _run(context, () => notifier.softDelete(item.id));
    }
  }

  Future<void> _hardDelete(BuildContext context, T item) async {
    if (await confirm(
          context,
          'Удалить «${nameOf(item)}» безвозвратно? Отменить будет нельзя.',
        ) &&
        context.mounted) {
      await _run(context, () => notifier.hardDelete(item.id));
    }
  }

  List<Widget> _actions(BuildContext context, T item) => [
    IconButton(
      tooltip: 'Открыть',
      icon: const Icon(Icons.visibility),
      onPressed: () => context.push(pathOf(item)),
    ),
    IconButton(
      tooltip: 'Изменить',
      icon: const Icon(Icons.edit),
      onPressed: () => context.push('${pathOf(item)}/edit'),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: filters),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => context.push(newPath),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
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

class PaginationBar extends StatelessWidget {
  final PageResult result;
  final int size;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;

  const PaginationBar({
    super.key,
    required this.result,
    required this.size,
    required this.onPage,
    required this.onSize,
  });

  @override
  Widget build(BuildContext context) {
    final page = result.page;
    final last = result.totalPages;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        IconButton(
          tooltip: 'Первая',
          icon: const Icon(Icons.first_page),
          onPressed: page > 1 ? () => onPage(1) : null,
        ),
        IconButton(
          tooltip: 'Предыдущая',
          icon: const Icon(Icons.chevron_left),
          onPressed: page > 1
              ? () => onPage(page > last ? last : page - 1)
              : null,
        ),
        Text('Страница $page из $last'),
        IconButton(
          tooltip: 'Следующая',
          icon: const Icon(Icons.chevron_right),
          onPressed: result.hasNext ? () => onPage(page + 1) : null,
        ),
        IconButton(
          tooltip: 'Последняя',
          icon: const Icon(Icons.last_page),
          onPressed: page != last ? () => onPage(last) : null,
        ),
        Text('Всего записей: ${result.total}'),
        const SizedBox(width: 16),
        const Text('На странице:'),
        DropdownButton<int>(
          value: size,
          items: [
            for (final s in pageSizes)
              DropdownMenuItem(value: s, child: Text('$s')),
          ],
          onChanged: (s) {
            if (s != null) onSize(s);
          },
        ),
      ],
    );
  }
}

class StatusView extends StatelessWidget {
  final LoadStatus status;
  final String? error;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;

  const StatusView({
    super.key,
    required this.status,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(error ?? 'Ошибка'),
              const SizedBox(height: 8),
              FilledButton(onPressed: onRetry, child: const Text('Повторить')),
            ],
          ),
        );
      case LoadStatus.success:
        if (isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48),
                SizedBox(height: 8),
                Text('Ничего не найдено. Измените условия поиска.'),
              ],
            ),
          );
        }
        return child;
    }
  }
}

Future<bool> confirm(
  BuildContext context,
  String text, {
  String okLabel = 'Удалить',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Подтверждение'),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(okLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
