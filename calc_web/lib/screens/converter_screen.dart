import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/currency.dart';
import '../logic/settings.dart';
import 'calculator_screen.dart' show numberValidator;
import 'page.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late String _from;
  late String _to;

  @override
  void initState() {
    super.initState();
    final settings = Settings.instance;
    _from = rates.containsKey(settings.lastFrom) ? settings.lastFrom! : 'USD';
    _to = rates.containsKey(settings.lastTo) ? settings.lastTo! : 'RUB';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _amountValidator(String? value) {
    final error = numberValidator(value);
    if (error != null) return error;
    if (parseNumber(value)! < 0) return 'Сумма не может быть отрицательной';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final uri = Uri(path: '/converter/result', queryParameters: {
      'from': _from,
      'to': _to,
      'amount': _amountController.text.trim().replaceAll(',', '.'),
    });
    context.go(uri.toString());
  }

  List<DropdownMenuItem<String>> get _items => rates.keys
      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
      .toList();

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Конвертер валют',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _from,
              decoration: const InputDecoration(labelText: 'Из валюты'),
              items: _items,
              onChanged: (value) {
                setState(() => _from = value!);
                Settings.instance.savePair(_from, _to);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _to,
              decoration: const InputDecoration(labelText: 'В валюту'),
              items: _items,
              onChanged: (value) {
                setState(() => _to = value!);
                Settings.instance.savePair(_from, _to);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Сумма'),
              validator: _amountValidator,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Конвертировать'),
            ),
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
