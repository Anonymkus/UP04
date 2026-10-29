import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../validators.dart';
import 'common.dart';
import 'entity_list_view.dart';

class TextFieldSpec extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Validator validator;
  final bool number;
  final String? hint;

  const TextFieldSpec({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.number = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: number ? TextInputType.number : null,
      validator: validator,
    );
  }
}

class MultiSelectField extends FormField<List<int>> {
  MultiSelectField({
    super.key,
    required String label,
    required List<(int, String)> options,
    required List<int> initialValue,
    required ValueChanged<List<int>> onChanged,
    super.validator,
  }) : super(
         initialValue: initialValue,
         builder: (field) => InputDecorator(
           decoration: InputDecoration(
             labelText: label,
             errorText: field.errorText,
             border: const OutlineInputBorder(),
           ),
           child: Wrap(
             spacing: 8,
             runSpacing: 8,
             children: [
               for (final (id, name) in options)
                 FilterChip(
                   label: Text(name),
                   selected: field.value!.contains(id),
                   onSelected: (selected) {
                     final next = [...field.value!];
                     selected ? next.add(id) : next.remove(id);
                     field.didChange(next);
                     onChanged(next);
                   },
                 ),
             ],
           ),
         ),
       );
}

class EntityForm<T> extends StatefulWidget {
  final String title;
  final String backPath;
  final Future<T?> Function()? load;
  final void Function(T item)? onLoaded;
  final List<Widget> Function(Map<String, String> errors) fields;
  final Future<void> Function() onSave;

  const EntityForm({
    super.key,
    required this.title,
    required this.backPath,
    required this.fields,
    required this.onSave,
    this.load,
    this.onLoaded,
  });

  @override
  State<EntityForm<T>> createState() => _EntityFormState<T>();
}

class _EntityFormState<T> extends State<EntityForm<T>> {
  final _formKey = GlobalKey<FormState>();
  final _errors = <String, String>{};
  bool _dirty = false;
  bool _saving = false;
  bool _submitted = false;
  bool _loading = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    final load = widget.load;
    if (load == null) return;
    _loading = true;
    load().then((item) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (item == null) {
          _notFound = true;
        } else {
          widget.onLoaded?.call(item);
        }
      });
    });
  }

  void _exit() =>
      context.canPop() ? context.pop() : context.go(widget.backPath);

  Future<bool> _confirmLeave() => confirm(
    context,
    'Есть несохранённые изменения. Уйти без сохранения?',
    okLabel: 'Уйти',
  );

  Future<void> _leave() async {
    if (_dirty && !await _confirmLeave()) return;
    if (mounted) _exit();
  }

  Future<void> _submit() async {
    _errors.clear();
    if (!_submitted) setState(() => _submitted = true);
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave();
      if (!mounted) return;
      _dirty = false;
      _exit();
    } on ValidationException catch (e) {
      if (!mounted) return;
      _errors.addAll(e.errors);
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_notFound) {
      body = const Center(child: Text('Запись не найдена'));
    } else {
      body = Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        onChanged: () {
          _errors.clear();
          if (!_dirty) setState(() => _dirty = true);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              children: [
                for (final field in widget.fields(_errors)) ...[
                  field,
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Сохранение...' : 'Сохранить'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmLeave() && mounted) _exit();
      },
      child: AppScaffold(
        title: widget.title,
        backPath: widget.backPath,
        onBack: _leave,
        body: body,
      ),
    );
  }
}
