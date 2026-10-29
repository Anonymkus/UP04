import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/appointment_repository.dart';
import 'repositories/barber_repository.dart';
import 'repositories/branch_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/repository.dart';
import 'repositories/service_repository.dart';
import 'router.dart';
import 'state/notifiers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final prefs = await SharedPreferences.getInstance();
  checkStorageVersion(prefs);

  final appointments = PersistentAppointmentRepository(prefs);
  final barbers = PersistentBarberRepository(prefs);
  final services = PersistentServiceRepository(prefs);
  final branches = PersistentBranchRepository(prefs);
  final clients = PersistentClientRepository(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AppointmentListNotifier(appointments, services, barbers, branches)
                ..loadLookups(),
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

class BarbershopApp extends StatefulWidget {
  const BarbershopApp({super.key});

  @override
  State<BarbershopApp> createState() => _BarbershopAppState();
}

class _BarbershopAppState extends State<BarbershopApp> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final notice in storageNotices) {
        _messenger.currentState?.showSnackBar(SnackBar(content: Text(notice)));
      }
      storageNotices.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Барбершоп',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messenger,
      routerConfig: appRouter,
    );
  }
}
