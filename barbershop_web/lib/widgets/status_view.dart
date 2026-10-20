import 'package:flutter/material.dart';

import '../state/entity_list_notifier.dart';

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
