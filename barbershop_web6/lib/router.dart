import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/permissions.dart';
import 'screens/admin_screens.dart' deferred as admin;
import 'screens/appointments_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/barbers_screen.dart';
import 'screens/branches_screen.dart' deferred as branches;
import 'screens/clients_screen.dart' deferred as clients;
import 'screens/home_screen.dart';
import 'screens/my_appointments_screen.dart' deferred as mine;
import 'screens/services_screen.dart';
import 'state/auth_notifier.dart';
import 'widgets/common.dart';

int _id(GoRouterState state) => int.tryParse(state.pathParameters['id']!) ?? 0;

List<GoRoute> _entityRoutes(
  String path, {
  required Widget Function(Map<String, String> params) list,
  required Widget Function(int id) detail,
  required Widget Function(int? id) form,
}) => [
  GoRoute(
    path: path,
    builder: (context, state) => list(state.uri.queryParameters),
  ),
  GoRoute(path: '$path/new', builder: (context, state) => form(null)),
  GoRoute(path: '$path/:id', builder: (context, state) => detail(_id(state))),
  GoRoute(
    path: '$path/:id/edit',
    builder: (context, state) => form(_id(state)),
  ),
];

GoRouter buildRouter(AuthNotifier auth) => GoRouter(
  refreshListenable: auth,
  initialLocation: '/login',
  redirect: (context, state) {
    final path = state.matchedLocation;
    final isPublic = path == '/login' || path == '/register';
    final user = auth.user;
    if (user == null) {
      if (isPublic) return null;
      if (path == '/') return '/login';
      return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
    }
    if (isPublic) return state.uri.queryParameters['from'] ?? '/';
    return canOpen(user.role, path) ? null : '/forbidden';
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/forbidden',
      builder: (context, state) => const ForbiddenScreen(),
    ),
    GoRoute(
      path: '/my-appointments',
      builder: (context, state) =>
          _Deferred(mine.loadLibrary, () => mine.MyAppointmentsScreen()),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) =>
          _Deferred(admin.loadLibrary, () => admin.UsersScreen()),
    ),
    GoRoute(
      path: '/admin/stats',
      builder: (context, state) =>
          _Deferred(admin.loadLibrary, () => admin.StatsScreen()),
    ),
    ..._entityRoutes(
      '/appointments',
      list: appointmentsList,
      detail: appointmentDetail,
      form: (id) => AppointmentFormScreen(id: id),
    ),
    ..._entityRoutes(
      '/barbers',
      list: barbersList,
      detail: barberDetail,
      form: (id) => BarberFormScreen(id: id),
    ),
    ..._entityRoutes(
      '/services',
      list: servicesList,
      detail: serviceDetail,
      form: (id) => ServiceFormScreen(id: id),
    ),
    ..._entityRoutes(
      '/branches',
      list: (p) =>
          _Deferred(branches.loadLibrary, () => branches.branchesList(p)),
      detail: (id) =>
          _Deferred(branches.loadLibrary, () => branches.branchDetail(id)),
      form: (id) => _Deferred(
        branches.loadLibrary,
        () => branches.BranchFormScreen(id: id),
      ),
    ),
    ..._entityRoutes(
      '/clients',
      list: (p) => _Deferred(clients.loadLibrary, () => clients.clientsList(p)),
      detail: (id) =>
          _Deferred(clients.loadLibrary, () => clients.clientDetail(id)),
      form: (id) => _Deferred(
        clients.loadLibrary,
        () => clients.ClientFormScreen(id: id),
      ),
    ),
  ],
  errorBuilder: (context, state) => AppScaffold(
    title: 'Страница не найдена',
    body: Center(child: Text('Адрес ${state.uri} не существует')),
  ),
);

class _Deferred extends StatefulWidget {
  final Future<void> Function() load;
  final Widget Function() build;

  const _Deferred(this.load, this.build);

  @override
  State<_Deferred> createState() => _DeferredState();
}

class _DeferredState extends State<_Deferred> {
  late final Future<void> _loaded = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loaded,
    builder: (context, snapshot) =>
        snapshot.connectionState == ConnectionState.done
        ? widget.build()
        : const Center(child: CircularProgressIndicator()),
  );
}
