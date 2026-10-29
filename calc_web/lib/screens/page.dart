import 'package:flutter/material.dart';

import '../logic/settings.dart';

class AppPage extends StatelessWidget {
  final String title;
  final Widget child;

  const AppPage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: Settings.instance.toggleTheme,
            child: const Text('Сменить тему'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: child,
          ),
        ),
      ),
    );
  }
}
