import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'repositories/appointment_repository.dart';
import 'repositories/barber_repository.dart';
import 'repositories/in_memory_appointment_repository.dart';
import 'repositories/in_memory_barber_repository.dart';
import 'router.dart';
import 'state/appointment_list_notifier.dart';
import 'state/barber_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(
    MultiProvider(
      providers: [
        Provider<AppointmentRepository>(
          create: (_) => InMemoryAppointmentRepository(),
        ),
        Provider<BarberRepository>(create: (_) => InMemoryBarberRepository()),
        ChangeNotifierProvider(
          create: (context) => AppointmentListNotifier(
            context.read<AppointmentRepository>(),
            context.read<BarberRepository>(),
          )..loadLookups(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              BarberListNotifier(context.read<BarberRepository>()),
        ),
      ],
      child: const BarbershopApp(),
    ),
  );
}

class BarbershopApp extends StatelessWidget {
  const BarbershopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Барбершоп',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
