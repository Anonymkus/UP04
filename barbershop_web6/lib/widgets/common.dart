import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../state/auth_notifier.dart';

class Section {
  final String path;
  final String title;
  final IconData icon;

  const Section(this.path, this.title, this.icon);
}

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

  static const sections = [
    Section('/', 'Главная', Icons.home),
    Section('/my-appointments', 'Мои записи', Icons.event_note),
    Section('/appointments', 'Записи', Icons.event),
    Section('/barbers', 'Барберы', Icons.content_cut),
    Section('/services', 'Услуги', Icons.design_services),
    Section('/branches', 'Филиалы', Icons.store),
    Section('/clients', 'Клиенты', Icons.people),
    Section('/admin/users', 'Пользователи', Icons.manage_accounts),
    Section('/admin/stats', 'Статистика', Icons.bar_chart),
  ];

  static const maxContentWidth = 1200.0;

  int _selected(BuildContext context, List<Section> items) {
    final path =
        GoRouter.maybeOf(context)?.routeInformationProvider.value.uri.path ??
        '/';
    var best = -1;
    for (var i = 0; i < items.length; i++) {
      final p = items[i].path;
      final match = p == '/' ? path == '/' : path.startsWith(p);
      if (match && (best == -1 || p.length > items[best].path.length)) {
        best = i;
      }
    }
    return best;
  }

  Future<void> _showMore(BuildContext context, List<Section> rest) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => ListView(
          shrinkWrap: true,
          children: [
            for (final s in rest)
              ListTile(
                leading: Icon(s.icon),
                title: Text(s.title),
                onTap: () {
                  Navigator.pop(sheet);
                  context.go(s.path);
                },
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 600;
    final items = user == null
        ? <Section>[]
        : [
            for (final s in sections)
              if (canOpen(user.role, s.path)) s,
          ];
    final selected = _selected(context, items);

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(padding: EdgeInsets.all(narrow ? 8 : 16), child: body),
      ),
    );

    Widget? bottomBar;
    Widget page = content;
    if (items.length >= 2 && narrow) {
      final shown = items.length > 5 ? items.sublist(0, 4) : items;
      final rest = items.length > 5 ? items.sublist(4) : <Section>[];
      bottomBar = NavigationBar(
        selectedIndex: selected >= 0 && selected < shown.length
            ? selected
            : (rest.isEmpty ? 0 : shown.length),
        onDestinationSelected: (i) => i < shown.length
            ? context.go(shown[i].path)
            : _showMore(context, rest),
        destinations: [
          for (final s in shown)
            NavigationDestination(icon: Icon(s.icon), label: s.title),
          if (rest.isNotEmpty)
            const NavigationDestination(
              icon: Icon(Icons.more_horiz),
              label: 'Ещё',
            ),
        ],
      );
    } else if (items.length >= 2) {
      final extended = width >= 1200;
      page = Row(
        children: [
          NavigationRail(
            extended: extended,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedIndex: selected >= 0 ? selected : null,
            onDestinationSelected: (i) => context.go(items[i].path),
            destinations: [
              for (final s in items)
                NavigationRailDestination(
                  icon: Icon(s.icon),
                  label: Text(s.title),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        leading: backPath == null
            ? null
            : IconButton(
                tooltip: 'Назад',
                icon: const Icon(Icons.arrow_back),
                onPressed:
                    onBack ??
                    () => context.canPop()
                        ? context.pop()
                        : context.go(backPath!),
              ),
        actions: [
          if (user != null) ...[
            if (!narrow)
              Flexible(
                child: Text(
                  '${user.fullName} (${user.role.title})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            narrow
                ? IconButton(
                    tooltip: 'Выйти',
                    onPressed: auth.logout,
                    icon: const Icon(Icons.logout),
                  )
                : TextButton.icon(
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
        ],
      ),
      body: page,
      bottomNavigationBar: bottomBar,
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
