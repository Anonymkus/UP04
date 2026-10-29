import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'repositories/repositories.dart';
import 'router.dart';
import 'state/notifiers.dart';

void main() {
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;

  final dio = buildDio();
  final appointments = appointmentRepository(dio);
  final barbers = barberRepository(dio);
  final services = serviceRepository(dio);
  final branches = branchRepository(dio);
  final clients = clientRepository(dio);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppointmentListNotifier(
            appointments,
            services,
            barbers,
            branches,
            clients,
          )..loadLookups(),
        ),
        ChangeNotifierProvider(
          create: (_) => BarberListNotifier(barbers, branches)..loadLookups(),
        ),
        ChangeNotifierProvider(create: (_) => ServiceListNotifier(services)),
        ChangeNotifierProvider(
          create: (_) => BranchListNotifier(branches, barbers),
        ),
        ChangeNotifierProvider(create: (_) => ClientListNotifier(clients)),
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
