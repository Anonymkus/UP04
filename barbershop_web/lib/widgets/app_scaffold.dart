import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String? backPath;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.backPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: backPath == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go(backPath!),
              ),
        actions: [
          TextButton(
            onPressed: () => context.go('/appointments'),
            child: const Text('Записи'),
          ),
          TextButton(
            onPressed: () => context.go('/barbers'),
            child: const Text('Барберы'),
          ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: body),
    );
  }
}
