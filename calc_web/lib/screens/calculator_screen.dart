import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/calculator.dart';
import 'page.dart';

String? numberValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Введите число';
  if (parseNumber(value) == null) return 'Это не число';
  return null;
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  String _operation = '+';

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final uri = Uri(path: '/calculator/result', queryParameters: {
      'a': _aController.text.trim().replaceAll(',', '.'),
      'op': _operation,
      'b': _bController.text.trim().replaceAll(',', '.'),
    });
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Калькулятор',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _aController,
              decoration: const InputDecoration(labelText: 'Первое число'),
              validator: numberValidator,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _operation,
              decoration: const InputDecoration(labelText: 'Операция'),
              items: operations
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (value) => setState(() => _operation = value ?? '+'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bController,
              decoration: const InputDecoration(labelText: 'Второе число'),
              validator: numberValidator,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _submit, child: const Text('Вычислить')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}
