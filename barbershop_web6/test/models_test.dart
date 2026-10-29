import 'package:barbershop_web/models/appointment.dart';
import 'package:barbershop_web/models/barber.dart';
import 'package:barbershop_web/models/client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('запись разбирает развёрнутые связи из ответа сервера', () {
    final a = Appointment.fromJson({
      'id': 5,
      'client': {'id': 3, 'fullName': 'Сидоров'},
      'barber': {'id': 2, 'fullName': 'Кузнецов'},
      'services': [
        {'id': 1},
        {'id': 3},
      ],
      'date': '2026-10-01T10:00:00',
      'price': 2500,
    });
    expect(a.clientId, 3);
    expect(a.barberId, 2);
    expect(a.serviceIds, [1, 3]);
    expect(a.date, DateTime(2026, 10, 1, 10));
  });

  test('отсутствующие поля не приводят к исключению', () {
    final c = Client.fromJson({'id': 1});
    expect(c.fullName, '');
    expect(c.card.number, '');
    final a = Appointment.fromJson({'id': 2, 'price': null});
    expect(a.price, 0);
    expect(a.serviceIds, isEmpty);
  });

  test('барбер принимает и branchId, и вложенный branch', () {
    expect(Barber.fromJson({'id': 1, 'branchId': 4}).branchId, 4);
    expect(
      Barber.fromJson({
        'id': 1,
        'branch': {'id': 2},
      }).branchId,
      2,
    );
  });
}
