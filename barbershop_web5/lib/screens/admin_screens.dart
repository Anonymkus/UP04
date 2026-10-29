import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/user.dart';
import '../state/auth_notifier.dart';
import '../state/notifiers.dart';
import '../widgets/common.dart';
import '../widgets/entity_list_view.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminNotifier>().loadUsers(),
    );
  }

  Future<void> _setRole(AdminNotifier n, AppUser user, Role role) async {
    try {
      await n.setRole(user, role);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<AdminNotifier>();
    final me = context.watch<AuthNotifier>().user;
    return AppScaffold(
      title: 'Пользователи и роли',
      body: StatusView(
        status: n.status,
        error: n.error,
        isEmpty: n.users.isEmpty,
        onRetry: n.loadUsers,
        child: ListView(
          children: [
            for (final u in n.users)
              ListTile(
                title: Text('${u.fullName} (${u.username})'),
                trailing: DropdownButton<Role>(
                  value: u.role,
                  items: [
                    for (final r in Role.values)
                      DropdownMenuItem(value: r, child: Text(r.title)),
                  ],
                  onChanged: u.id == me?.id
                      ? null
                      : (r) => r == null ? null : _setRole(n, u, r),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminNotifier>().loadStats(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<AdminNotifier>();
    final s = n.stats;
    final users = (s['users'] as Map?) ?? const {};
    final top = (s['topBarbers'] as List?) ?? const [];
    return AppScaffold(
      title: 'Статистика',
      body: StatusView(
        status: n.status,
        error: n.error,
        isEmpty: s.isEmpty,
        onRetry: n.loadStats,
        child: ListView(
          children: [
            DetailRow.text('Активных записей', '${s['appointments']}'),
            DetailRow.text('Выручка', '${s['revenue']} ₽'),
            DetailRow.text('Клиентов', '${s['clients']}'),
            DetailRow.text('Барберов', '${s['barbers']}'),
            DetailRow.text(
              'Пользователи',
              users.entries
                  .map((e) => '${Role.parse(e.key).title}: ${e.value}')
                  .join(', '),
            ),
            DetailRow(
              'Самые загруженные',
              Text(
                top.map((b) => '${b['fullName']} — ${b['count']}').join('\n'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
