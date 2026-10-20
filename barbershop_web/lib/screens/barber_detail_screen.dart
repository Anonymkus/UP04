import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/barber.dart';
import '../state/barber_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/detail_view.dart';

class BarberDetailScreen extends StatefulWidget {
  final int id;

  const BarberDetailScreen({super.key, required this.id});

  @override
  State<BarberDetailScreen> createState() => _BarberDetailScreenState();
}

class _BarberDetailScreenState extends State<BarberDetailScreen> {
  late final Future<Barber?> _future = context
      .read<BarberListNotifier>()
      .findById(widget.id);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Карточка барбера',
      backPath: '/barbers',
      body: DetailView<Barber>(
        future: _future,
        notFoundText: 'Барбер ${widget.id} не найден',
        builder: (barber) => [
          Text(
            barber.fullName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          DetailRow.text('ФИО', barber.fullName),
          DetailRow.text('Год рождения', '${barber.birthYear}'),
          if (barber.isDeleted)
            DetailRow.text('Удалён', barber.deletedAt.toString()),
        ],
      ),
    );
  }
}
