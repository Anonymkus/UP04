import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final bool Function(T item)? isMuted;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.isMuted,
  });

  bool _muted(T item) => isMuted?.call(item) ?? false;

  Widget _cell(Widget child, double maxWidth) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: DefaultTextStyle.merge(
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 600
          ? _buildCards(context)
          : _buildTable(context),
    );
  }

  Widget _buildTable(BuildContext context) {
    final sortIndex = columns.indexWhere(
      (c) => c.sortField != null && c.sortField == sortField,
    );
    final mutedColor = WidgetStatePropertyAll(
      Theme.of(context).disabledColor.withAlpha(30),
    );
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: sortIndex == -1 ? null : sortIndex,
          sortAscending: sortAscending,
          showCheckboxColumn: onToggleSelect != null,
          columns: [
            for (final c in columns)
              DataColumn(
                label: Text(c.label),
                numeric: c.numeric,
                onSort: c.sortField == null || onSort == null
                    ? null
                    : (_, _) => onSort!(c.sortField!),
              ),
            if (actions != null) const DataColumn(label: Text('Действия')),
          ],
          rows: [
            for (final item in items)
              DataRow(
                selected: selected.contains(idOf(item)),
                onSelectChanged: onToggleSelect == null
                    ? null
                    : (_) => onToggleSelect!(idOf(item)),
                color: _muted(item) ? mutedColor : null,
                cells: [
                  for (final c in columns) DataCell(_cell(c.build(item), 260)),
                  if (actions != null)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!(item),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idOf(item);
        return Card(
          color: _muted(item)
              ? Theme.of(context).disabledColor.withAlpha(30)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onToggleSelect != null)
                      Checkbox(
                        value: selected.contains(id),
                        onChanged: (_) => onToggleSelect!(id),
                      ),
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: Theme.of(context).textTheme.titleMedium,
                        child: _cell(
                          columns.first.build(item),
                          double.infinity,
                        ),
                      ),
                    ),
                  ],
                ),
                for (final c in columns.skip(1))
                  Row(
                    children: [
                      Text('${c.label}: '),
                      Flexible(child: _cell(c.build(item), double.infinity)),
                    ],
                  ),
                if (actions != null)
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    children: actions!(item),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
