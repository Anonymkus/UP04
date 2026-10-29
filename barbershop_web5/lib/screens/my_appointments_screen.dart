import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/common.dart';
import '../state/notifiers.dart';
import '../widgets/common.dart';
import '../widgets/entity_list_view.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MyAppointmentsNotifier>().load(),
    );
  }

  Future<void> _cancel(MyAppointmentsNotifier n, int id) async {
    final ok = await confirm(context, 'Отменить запись?', okLabel: 'Отменить');
    if (!ok) return;
    try {
      await n.cancel(id);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<MyAppointmentsNotifier>();
    return AppScaffold(
      title: 'Мои записи',
      body: StatusView(
        status: n.status,
        error: n.error,
        isEmpty: n.items.isEmpty,
        onRetry: n.load,
        child: ListView(
          children: [
            for (final a in n.items)
              Card(
                child: ListTile(
                  title: Text(
                    '${formatDateTime(a.date)} — ${n.serviceNames(a)}',
                  ),
                  subtitle: Text(
                    'Барбер: ${n.barberName(a)}, стоимость ${a.price} ₽',
                  ),
                  trailing: TextButton(
                    onPressed: () => _cancel(n, a.id),
                    child: const Text('Отменить'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
