import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/appointment.dart';
import 'screens/appointments_screen.dart';
import 'screens/barbers_screen.dart';
import 'screens/branches_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/services_screen.dart';
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

final appRouter = GoRouter(
  initialLocation: '/appointments',
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/appointments'),
    ..._entityRoutes(
      '/appointments',
      list: (p) => AppointmentsScreen(query: AppointmentQuery.fromParams(p)),
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
      list: branchesList,
      detail: branchDetail,
      form: (id) => BranchFormScreen(id: id),
    ),
    ..._entityRoutes(
      '/clients',
      list: clientsList,
      detail: clientDetail,
      form: (id) => ClientFormScreen(id: id),
    ),
  ],
  errorBuilder: (context, state) => AppScaffold(
    title: 'Страница не найдена',
    body: Center(child: Text('Адрес ${state.uri} не существует')),
  ),
);
