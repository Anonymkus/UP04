import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/result.dart';
import 'page.dart';

class ResultScreen extends StatelessWidget {
  final String title;
  final CalcResult result;
  final String backPath;

  const ResultScreen({
    super.key,
    required this.title,
    required this.result,
    required this.backPath,
  });

  @override
  Widget build(BuildContext context) {
    final text = switch (result) {
      CalcSuccess(:final text) => text,
      CalcFailure(:final message) => 'Ошибка: $message',
    };
    return AppPage(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(backPath),
            child: const Text('Назад к форме'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('На главную'),
          ),
        ],
      ),
    );
  }
}
