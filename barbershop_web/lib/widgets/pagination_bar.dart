import 'package:flutter/material.dart';

import '../models/page_result.dart';
import '../models/query_params.dart';

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
