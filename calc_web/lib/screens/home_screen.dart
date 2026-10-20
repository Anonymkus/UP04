import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Главная',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () => context.go('/calculator'),
            child: const Text('Калькулятор'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/converter'),
            child: const Text('Конвертер валют'),
          ),
        ],
      ),
    );
  }
}
