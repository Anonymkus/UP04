import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/query_params.dart';
import '../state/appointment_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/detail_view.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final int id;

  const AppointmentDetailScreen({super.key, required this.id});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late final Future<Appointment?> _future = context
      .read<AppointmentListNotifier>()
      .findById(widget.id);

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AppointmentListNotifier>();
    return AppScaffold(
      title: 'Карточка записи',
      backPath: '/appointments',
      body: DetailView<Appointment>(
        future: _future,
        notFoundText: 'Запись ${widget.id} не найдена',
        builder: (a) => [
          Text(a.clientName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          DetailRow.text('Дата и время', formatDateTime(a.date)),
          DetailRow.text('Телефон', a.phone),
          DetailRow.text('Услуга', notifier.serviceName(a)),
          DetailRow.text('Стоимость', '${a.price} ₽'),
          DetailRow(
            'Барбер',
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                label: Text(notifier.barberName(a)),
                onPressed: () => context.push('/barbers/${a.barberId}'),
              ),
            ),
          ),
          if (a.isDeleted) DetailRow.text('Удалена', a.deletedAt.toString()),
        ],
      ),
    );
  }
}
