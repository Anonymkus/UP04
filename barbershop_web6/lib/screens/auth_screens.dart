import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';
import '../validators.dart';
import '../widgets/common.dart';
import '../widgets/entity_form.dart';

class _AuthLayout extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _AuthLayout({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthNotifier>().login(
        _username.text.trim(),
        _password.text,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = context.watch<AuthNotifier>().message;
    final error = Theme.of(context).colorScheme.error;
    return _AuthLayout(
      title: 'Вход',
      children: [
        if (notice != null) Text(notice, style: TextStyle(color: error)),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFieldSpec(
                label: 'Логин',
                controller: _username,
                validator: notEmpty,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                ),
                validator: notEmpty,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: error)),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Войти'),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: const Text('Нет учётной записи? Зарегистрироваться'),
        ),
      ],
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fields = {
    for (final key in ['username', 'password', 'fullName', 'email', 'phone'])
      key: TextEditingController(),
  };
  final _errors = <String, String>{};
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    _errors.clear();
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthNotifier>().register({
        for (final e in _fields.entries) e.key: e.value.text.trim(),
      });
    } on ValidationException catch (e) {
      _errors.addAll(e.errors);
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String key, String label, Validator validator) =>
        TextFieldSpec(
          label: label,
          controller: _fields[key]!,
          validator: all([validator, serverError(_errors, key)]),
        );

    return _AuthLayout(
      title: 'Регистрация',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              field('username', 'Логин', all([notEmpty, minLength(3)])),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fields['password'],
                obscureText: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  helperText:
                      'Не короче 8 символов, цифра и специальный символ',
                  border: OutlineInputBorder(),
                ),
                validator: all([
                  strongPassword,
                  serverError(_errors, 'password'),
                ]),
              ),
              const SizedBox(height: 16),
              field('fullName', 'ФИО', all([notEmpty, minLength(5)])),
              const SizedBox(height: 16),
              field('email', 'Почта', all([notEmpty, email])),
              const SizedBox(height: 16),
              field('phone', 'Телефон', all([notEmpty, phone])),
            ],
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Зарегистрироваться'),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Уже есть учётная запись? Войти'),
        ),
      ],
    );
  }
}
