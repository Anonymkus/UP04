import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/barber.dart';
import '../models/common.dart';
import '../state/notifiers.dart';
import '../validators.dart';
import '../widgets/common.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import 'simple_screen.dart';

Widget barbersList(Map<String, String> params) =>
    SimpleListScreen<Barber, BarberListNotifier>(
      title: 'Барберы',
      query: SimpleQuery.fromParams(
        '/barbers',
        BarberListNotifier.barberSort,
        params,
      ),
      searchLabel: 'Поиск по ФИО',
      nameOf: (b) => b.fullName,
      columns: (n) => [
        TableColumnSpec(
          label: '№',
          sortField: 'id',
          numeric: true,
          build: (b) => Text('${b.id}'),
        ),
        TableColumnSpec(
          label: 'ФИО',
          sortField: 'fullName',
          build: (b) => Text(b.fullName),
        ),
        TableColumnSpec(
          label: 'Год рождения',
          sortField: 'birthYear',
          numeric: true,
          build: (b) => Text('${b.birthYear}'),
        ),
        TableColumnSpec(label: 'Филиал', build: (b) => Text(n.branchName(b))),
      ],
    );

Widget barberDetail(int id) => SimpleDetailScreen<Barber, BarberListNotifier>(
  id: id,
  title: 'Карточка барбера',
  backPath: '/barbers',
  notFoundText: 'Барбер $id не найден',
  rows: (context, n, b) => [
    Text(b.fullName, style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 12),
    DetailRow.text('Год рождения', '${b.birthYear}'),
    DetailRow.text('Филиал', n.branchName(b)),
  ],
);

class BarberFormScreen extends StatefulWidget {
  final int? id;

  const BarberFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BarberFormScreen> createState() => _BarberFormScreenState();
}

class _BarberFormScreenState extends State<BarberFormScreen> {
  final _fullName = TextEditingController();
  final _birthYear = TextEditingController();
  int? _branchId;
  Barber? _original;
  bool _loading = false;
  String? _notFound;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loading = true;
      context.read<BarberListNotifier>().findById(widget.id!).then((b) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          if (b == null) {
            _notFound = 'Барбер ${widget.id} не найден';
            return;
          }
          _original = b;
          _fullName.text = b.fullName;
          _birthYear.text = '${b.birthYear}';
          _branchId = b.branchId;
        });
      });
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BarberListNotifier>();
    final branches = notifier.branches.where(
      (b) => b.deletedAt == null || b.id == _branchId,
    );
    return EntityForm(
      title: widget.isEditing ? 'Изменение барбера' : 'Новый барбер',
      backPath: '/barbers',
      loading: _loading,
      notFound: _notFound,
      fields: (errors) => [
        TextFieldSpec(
          label: 'ФИО',
          controller: _fullName,
          validator: all([notEmpty, minLength(5), maxLength(100)]),
        ),
        TextFieldSpec(
          label: 'Год рождения',
          controller: _birthYear,
          number: true,
          validator: all([notEmpty, intRange(1950, DateTime.now().year - 18)]),
        ),
        DropdownButtonFormField<int>(
          initialValue: branches.any((b) => b.id == _branchId)
              ? _branchId
              : null,
          decoration: const InputDecoration(
            labelText: 'Филиал',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final b in branches)
              DropdownMenuItem(value: b.id, child: Text(b.name)),
          ],
          onChanged: (v) => _branchId = v,
          validator: (v) => v == null ? 'Выберите филиал' : null,
        ),
      ],
      onSave: () async {
        await notifier.save(
          Barber(
            id: widget.id ?? 0,
            fullName: _fullName.text.trim(),
            birthYear: int.parse(_birthYear.text.trim()),
            branchId: _branchId!,
            deletedAt: _original?.deletedAt,
          ),
        );
        return {};
      },
    );
  }
}
