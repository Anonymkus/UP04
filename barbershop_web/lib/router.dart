import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/appointment_query.dart';
import 'models/barber_query.dart';
import 'screens/appointment_detail_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/barber_detail_screen.dart';
import 'screens/barbers_screen.dart';
import 'widgets/app_scaffold.dart';

int _id(GoRouterState state) => int.tryParse(state.pathParameters['id']!) ?? 0;

final appRouter = GoRouter(
  initialLocation: '/appointments',
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/appointments'),
    GoRoute(
      path: '/appointments',
      builder: (context, state) => AppointmentsScreen(
        query: AppointmentQuery.fromParams(state.uri.queryParameters),
      ),
    ),
    GoRoute(
      path: '/appointments/:id',
      builder: (context, state) => AppointmentDetailScreen(id: _id(state)),
    ),
    GoRoute(
      path: '/barbers',
      builder: (context, state) => BarbersScreen(
        query: BarberQuery.fromParams(state.uri.queryParameters),
      ),
    ),
    GoRoute(
      path: '/barbers/:id',
      builder: (context, state) => BarberDetailScreen(id: _id(state)),
    ),
  ],
  errorBuilder: (context, state) => AppScaffold(
    title: 'Страница не найдена',
    body: Center(child: Text('Адрес ${state.uri} не существует')),
  ),
);
