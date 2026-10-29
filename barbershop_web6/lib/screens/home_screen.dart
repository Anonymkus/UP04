import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../models/user.dart';
import '../state/auth_notifier.dart';
import '../widgets/common.dart';

const _abilities = {
  Role.client: [
    'Просмотр услуг и барберов',
    'Просмотр своих записей',
    'Отмена своей записи',
  ],
  Role.manager: [
    'Ведение записей клиентов',
    'Управление клиентами, барберами, услугами и филиалами',
    'Логическое удаление записей',
  ],
  Role.admin: [
    'Всё, что доступно менеджеру',
    'Управление пользователями и ролями',
    'Физическое удаление и восстановление записей',
    'Статистика',
  ],
};

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user!;
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Главная',
      body: ListView(
        children: [
          Text(
            'Здравствуйте, ${user.fullName}!',
            style: theme.textTheme.headlineSmall,
          ),
          Text('Роль: ${user.role.title}'),
          const SizedBox(height: 16),
          Text('Вам доступно:', style: theme.textTheme.titleMedium),
          for (final a in _abilities[user.role]!) Text('• $a'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 500
                  ? 1
                  : constraints.maxWidth < 900
                  ? 2
                  : 3;
              final width =
                  (constraints.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final s in AppScaffold.sections)
                    if (s.path != '/' && canOpen(user.role, s.path))
                      SizedBox(
                        width: width,
                        child: Card(
                          child: ListTile(
                            leading: Icon(s.icon),
                            title: Text(s.title),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go(s.path),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Доступ запрещён',
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            const Text('У вашей роли нет доступа к этой странице.'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}
