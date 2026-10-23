import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/common.dart';
import '../models/service.dart';
import '../state/notifiers.dart';
import '../validators.dart';
import '../widgets/common.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import 'entity_screen.dart';

Widget servicesList(Map<String, String> params) =>
    EntityListScreen<Service, SimpleQuery, ServiceListNotifier>(
      path: '/services',
      title: 'Услуги',
      query: SimpleQuery.fromParams(
        '/services',
        ServiceListNotifier.serviceSort,
        params,
      ),
      searchLabel: 'Поиск по названию',
      nameOf: (s) => s.name,
      columns: (n) => [
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (s) => Text(s.name),
        ),
        TableColumnSpec(
          label: 'Цена',
          sortField: 'price',
          numeric: true,
          build: (s) => Text('${s.price} ₽'),
        ),
        TableColumnSpec(
          label: 'Длительность',
          sortField: 'duration',
          numeric: true,
          build: (s) => Text('${s.duration} мин'),
        ),
      ],
    );

Widget serviceDetail(int id) =>
    EntityDetailScreen<Service, ServiceListNotifier>(
      id: id,
      title: 'Карточка услуги',
      backPath: '/services',
      notFoundText: 'Услуга $id не найдена',
      rows: (context, n, s) => [
        Text(s.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        DetailRow.text('Цена', '${s.price} ₽'),
        DetailRow.text('Длительность', '${s.duration} мин'),
      ],
    );

class ServiceFormScreen extends StatefulWidget {
  final int? id;

  const ServiceFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController();
  Service? _original;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<ServiceListNotifier>();
    return EntityForm<Service>(
      title: widget.isEditing ? 'Изменение услуги' : 'Новая услуга',
      backPath: '/services',
      load: widget.id == null ? null : () => notifier.findById(widget.id!),
      onLoaded: (s) {
        _original = s;
        _name.text = s.name;
        _price.text = '${s.price}';
        _duration.text = '${s.duration}';
      },
      fields: (errors) => [
        TextFieldSpec(
          label: 'Название',
          controller: _name,
          validator: all([notEmpty, minLength(3), maxLength(60)]),
        ),
        TextFieldSpec(
          label: 'Цена, ₽',
          controller: _price,
          number: true,
          validator: all([notEmpty, positiveInt, intRange(1, 100000)]),
        ),
        TextFieldSpec(
          label: 'Длительность, мин',
          controller: _duration,
          number: true,
          validator: all([notEmpty, positiveInt, intRange(5, 300)]),
        ),
      ],
      onSave: () async {
        await notifier.save(
          Service(
            id: widget.id ?? 0,
            name: _name.text.trim(),
            price: int.parse(_price.text.trim()),
            duration: int.parse(_duration.text.trim()),
            deletedAt: _original?.deletedAt,
          ),
        );
      },
    );
  }
}
