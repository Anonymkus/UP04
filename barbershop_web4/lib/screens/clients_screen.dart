import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/common.dart';
import '../state/notifiers.dart';
import '../validators.dart';
import '../widgets/common.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import 'entity_screen.dart';

Widget clientsList(Map<String, String> params) =>
    EntityListScreen<Client, SimpleQuery, ClientListNotifier>(
      path: '/clients',
      title: 'Клиенты',
      query: SimpleQuery.fromParams(
        '/clients',
        ClientListNotifier.clientSort,
        params,
      ),
      searchLabel: 'Поиск по ФИО, почте, телефону',
      nameOf: (c) => c.fullName,
      columns: (n) => [
        TableColumnSpec(
          label: 'ФИО',
          sortField: 'fullName',
          build: (c) => Text(c.fullName),
        ),
        TableColumnSpec(label: 'Телефон', build: (c) => Text(c.phone)),
        TableColumnSpec(
          label: 'Почта',
          sortField: 'email',
          build: (c) => Text(c.email),
        ),
        TableColumnSpec(label: 'Карта', build: (c) => Text(c.card.number)),
        TableColumnSpec(
          label: 'Скидка',
          sortField: 'discount',
          numeric: true,
          build: (c) => Text('${c.card.discount}%'),
        ),
      ],
    );

Widget clientDetail(int id) => EntityDetailScreen<Client, ClientListNotifier>(
  id: id,
  title: 'Карточка клиента',
  backPath: '/clients',
  notFoundText: 'Клиент $id не найден',
  rows: (context, n, c) => [
    Text(c.fullName, style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 12),
    DetailRow.text('Телефон', c.phone),
    DetailRow.text('Почта', c.email),
    DetailRow.text('Номер карты', c.card.number),
    DetailRow.text('Скидка', '${c.card.discount}%'),
  ],
);

class ClientFormScreen extends StatefulWidget {
  final int? id;

  const ClientFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _cardNumber = TextEditingController();
  final _discount = TextEditingController();
  Client? _original;

  @override
  void dispose() {
    for (final c in [_fullName, _phone, _email, _cardNumber, _discount]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<ClientListNotifier>();
    return EntityForm<Client>(
      title: widget.isEditing ? 'Изменение клиента' : 'Новый клиент',
      backPath: '/clients',
      load: widget.id == null ? null : () => notifier.findById(widget.id!),
      onLoaded: (c) {
        _original = c;
        _fullName.text = c.fullName;
        _phone.text = c.phone;
        _email.text = c.email;
        _cardNumber.text = c.card.number;
        _discount.text = '${c.card.discount}';
      },
      fields: (errors) => [
        TextFieldSpec(
          label: 'ФИО',
          controller: _fullName,
          validator: all([notEmpty, minLength(5), maxLength(100)]),
        ),
        TextFieldSpec(
          label: 'Телефон',
          controller: _phone,
          hint: '+7 999 123 45 67',
          validator: all([notEmpty, phone]),
        ),
        TextFieldSpec(
          label: 'Почта',
          controller: _email,
          validator: all([
            notEmpty,
            maxLength(100),
            email,
            serverError(errors, 'email'),
          ]),
        ),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Клубная карта',
            border: OutlineInputBorder(),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              TextFieldSpec(
                label: 'Номер карты',
                controller: _cardNumber,
                number: true,
                validator: all([
                  notEmpty,
                  digits(6),
                  serverError(errors, 'cardNumber'),
                ]),
              ),
              const SizedBox(height: 16),
              TextFieldSpec(
                label: 'Скидка, %',
                controller: _discount,
                number: true,
                validator: all([
                  notEmpty,
                  intRange(0, 30),
                  serverError(errors, 'cardDiscount'),
                ]),
              ),
            ],
          ),
        ),
      ],
      onSave: () async {
        final id = widget.id ?? 0;
        final emailValue = _email.text.trim();
        final card = _cardNumber.text.trim();
        await notifier.save(
          Client(
            id: id,
            fullName: _fullName.text.trim(),
            phone: _phone.text.trim(),
            email: emailValue,
            card: ClientCard(
              number: card,
              discount: int.parse(_discount.text.trim()),
            ),
            deletedAt: _original?.deletedAt,
          ),
        );
      },
    );
  }
}
