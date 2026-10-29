import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../state/auth_notifier.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String? backPath;
  final VoidCallback? onBack;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.backPath,
    this.onBack,
  });

  static const sections = {
    '/': 'Главная',
    '/my-appointments': 'Мои записи',
    '/appointments': 'Записи',
    '/barbers': 'Барберы',
    '/services': 'Услуги',
    '/branches': 'Филиалы',
    '/clients': 'Клиенты',
    '/admin/users': 'Пользователи',
    '/admin/stats': 'Статистика',
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: backPath == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed:
                    onBack ??
                    () => context.canPop()
                        ? context.pop()
                        : context.go(backPath!),
              ),
        actions: [
          if (user != null) ...[
            Text('${user.fullName} (${user.role.title})'),
            TextButton.icon(
              onPressed: auth.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
            ),
          ] else
            TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Войти'),
            ),
          if (user != null)
            PopupMenuButton<String>(
              tooltip: 'Разделы',
              icon: const Icon(Icons.menu),
              onSelected: (path) => context.go(path),
              itemBuilder: (_) => [
                for (final e in sections.entries)
                  if (canOpen(user.role, e.key))
                    PopupMenuItem(value: e.key, child: Text(e.value)),
              ],
            ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: body),
    );
  }
}

class DebouncedTextField extends StatefulWidget {
  final String value;
  final String label;
  final ValueChanged<String> onChanged;
  final double width;
  final bool digitsOnly;
  final Duration delay;

  const DebouncedTextField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.width = 280,
    this.digitsOnly = false,
    this.delay = const Duration(milliseconds: 400),
  });

  @override
  State<DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<DebouncedTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  Timer? _timer;

  @override
  void didUpdateWidget(DebouncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && !(_timer?.isActive ?? false)) {
      _controller.text = widget.value;
    }
  }

  void _schedule(String text) {
    _timer?.cancel();
    _timer = Timer(widget.delay, () => _emit(text));
  }

  void _emit(String text) {
    _timer?.cancel();
    if (text != widget.value) widget.onChanged(text);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: widget.digitsOnly ? TextInputType.number : null,
        inputFormatters: widget.digitsOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        onChanged: _schedule,
        onSubmitted: _emit,
      ),
    );
  }
}

class DetailView<T> extends StatelessWidget {
  final Future<T?> future;
  final String notFoundText;
  final List<Widget> Function(T value) builder;

  const DetailView({
    super.key,
    required this.future,
    required this.notFoundText,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Ошибка загрузки: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        final value = snapshot.data;
        if (value == null) return Center(child: Text(notFoundText));
        return ListView(children: builder(value));
      },
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final Widget child;

  const DetailRow(this.label, this.child, {super.key});

  DetailRow.text(this.label, String value, {super.key}) : child = Text(value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
