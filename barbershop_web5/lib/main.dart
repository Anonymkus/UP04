import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'repositories/auth_api.dart';
import 'repositories/repositories.dart';
import 'repositories/repository.dart';
import 'router.dart';
import 'state/auth_notifier.dart';
import 'state/notifiers.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;

  final prefs = await SharedPreferences.getInstance();
  final auth = AuthNotifier(prefs, AuthApi(buildDio()))..restore();
  final dio = buildDio(
    tokenProvider: () => auth.accessToken,
    onUnauthorized: auth.refreshTokens,
  );

  final appointments = appointmentRepository(dio);
  final barbers = barberRepository(dio);
  final services = serviceRepository(dio);
  final branches = branchRepository(dio);
  final clients = clientRepository(dio);

  final notifiers = (
    appointments: AppointmentListNotifier(
      appointments,
      services,
      barbers,
      branches,
      clients,
    ),
    barbers: BarberListNotifier(barbers, branches),
    services: ServiceListNotifier(services),
    branches: BranchListNotifier(branches, barbers),
    clients: ClientListNotifier(clients),
  );

  var lastUserId = auth.user?.id;
  auth.addListener(() {
    if (auth.user?.id == lastUserId) return;
    lastUserId = auth.user?.id;
    for (final repo in <ApiRepository>[
      appointments,
      barbers,
      services,
      branches,
      clients,
    ]) {
      repo.clearCache();
    }
    for (final n in <EntityListNotifier>[
      notifiers.appointments,
      notifiers.barbers,
      notifiers.services,
      notifiers.branches,
      notifiers.clients,
    ]) {
      n.reset();
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: notifiers.appointments),
        ChangeNotifierProvider.value(value: notifiers.barbers),
        ChangeNotifierProvider.value(value: notifiers.services),
        ChangeNotifierProvider.value(value: notifiers.branches),
        ChangeNotifierProvider.value(value: notifiers.clients),
        ChangeNotifierProvider(
          create: (_) =>
              MyAppointmentsNotifier(appointments, services, barbers),
        ),
        ChangeNotifierProvider(create: (_) => AdminNotifier(AdminApi(dio))),
      ],
      child: BarbershopApp(auth: auth),
    ),
  );
}

class BarbershopApp extends StatefulWidget {
  final AuthNotifier auth;

  const BarbershopApp({super.key, required this.auth});

  @override
  State<BarbershopApp> createState() => _BarbershopAppState();
}

class _BarbershopAppState extends State<BarbershopApp> {
  late final _router = buildRouter(widget.auth);
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return MaterialApp.router(
      title: 'Барбершоп',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      scaffoldMessengerKey: _messenger,
      builder: (context, child) => !auth.isAuthenticated
          ? child!
          : InactivityWatcher(
              timeout: const Duration(minutes: 3),
              warnBefore: const Duration(seconds: 30),
              onWarn: () => _messenger.currentState?.showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 30),
                  content: Text(
                    'Нет активности. Сеанс завершится через 30 секунд.',
                  ),
                ),
              ),
              onActive: () => _messenger.currentState?.hideCurrentSnackBar(),
              onTimeout: () => auth.logout(
                reason: 'Сеанс завершён из-за неактивности (3 минуты).',
              ),
              child: child!,
            ),
    );
  }
}
