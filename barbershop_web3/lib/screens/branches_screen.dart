import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/barber.dart';
import '../models/branch.dart';
import '../models/common.dart';
import '../state/notifiers.dart';
import '../validators.dart';
import '../widgets/common.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import 'simple_screen.dart';

Widget branchesList(Map<String, String> params) =>
    SimpleListScreen<Branch, BranchListNotifier>(
      title: 'Филиалы',
      query: SimpleQuery.fromParams(
        '/branches',
        BranchListNotifier.branchSort,
        params,
      ),
      searchLabel: 'Поиск по названию или адресу',
      nameOf: (b) => b.name,
      columns: (n) => [
        TableColumnSpec(
          label: '№',
          sortField: 'id',
          numeric: true,
          build: (b) => Text('${b.id}'),
        ),
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (b) => Text(b.name),
        ),
        TableColumnSpec(
          label: 'Адрес',
          sortField: 'address',
          build: (b) => Text(b.address),
        ),
      ],
    );

Widget branchDetail(int id) => SimpleDetailScreen<Branch, BranchListNotifier>(
  id: id,
  title: 'Карточка филиала',
  backPath: '/branches',
  notFoundText: 'Филиал $id не найден',
  rows: (context, n, b) => [
    Text(b.name, style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 12),
    DetailRow.text('Адрес', b.address),
    DetailRow(
      'Барберы',
      FutureBuilder<List<Barber>>(
        future: n.barbersOf(b.id),
        builder: (context, snapshot) => Text(
          snapshot.data == null
              ? '...'
              : snapshot.data!.isEmpty
              ? 'нет'
              : snapshot.data!.map((x) => x.fullName).join('\n'),
        ),
      ),
    ),
  ],
);

class BranchFormScreen extends StatefulWidget {
  final int? id;

  const BranchFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  Branch? _original;
  bool _loading = false;
  String? _notFound;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loading = true;
      context.read<BranchListNotifier>().findById(widget.id!).then((b) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          if (b == null) {
            _notFound = 'Филиал ${widget.id} не найден';
            return;
          }
          _original = b;
          _name.text = b.name;
          _address.text = b.address;
        });
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<BranchListNotifier>();
    return EntityForm(
      title: widget.isEditing ? 'Изменение филиала' : 'Новый филиал',
      backPath: '/branches',
      loading: _loading,
      notFound: _notFound,
      fields: (errors) => [
        TextFieldSpec(
          label: 'Название',
          controller: _name,
          validator: all([notEmpty, minLength(2), maxLength(50)]),
        ),
        TextFieldSpec(
          label: 'Адрес',
          controller: _address,
          validator: all([notEmpty, minLength(5), maxLength(120)]),
        ),
      ],
      onSave: () async {
        await notifier.save(
          Branch(
            id: widget.id ?? 0,
            name: _name.text.trim(),
            address: _address.text.trim(),
            deletedAt: _original?.deletedAt,
          ),
        );
        return {};
      },
    );
  }
}
