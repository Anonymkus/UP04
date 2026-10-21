import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/branch.dart';
import '../models/client.dart';
import '../models/service.dart';

const seedServices = [
  Service(id: 1, name: 'Мужская стрижка', price: 1500, duration: 60),
  Service(id: 2, name: 'Стрижка машинкой', price: 900, duration: 30),
  Service(id: 3, name: 'Стрижка бороды', price: 1000, duration: 30),
  Service(id: 4, name: 'Стрижка и борода', price: 2200, duration: 90),
  Service(id: 5, name: 'Детская стрижка', price: 1000, duration: 45),
  Service(id: 6, name: 'Бритьё опасной бритвой', price: 1200, duration: 45),
  Service(id: 7, name: 'Камуфляж седины', price: 1300, duration: 30),
];

const seedBranches = [
  Branch(id: 1, name: 'Центральный', address: 'ул. Ленина, 10'),
  Branch(id: 2, name: 'Северный', address: 'пр. Мира, 45'),
  Branch(id: 3, name: 'Южный', address: 'ул. Садовая, 7'),
];

const seedBarbers = [
  Barber(
    id: 1,
    fullName: 'Смирнов Артём Игоревич',
    birthYear: 1994,
    branchId: 1,
  ),
  Barber(
    id: 2,
    fullName: 'Кузнецов Денис Олегович',
    birthYear: 1990,
    branchId: 2,
  ),
  Barber(
    id: 3,
    fullName: 'Попов Максим Сергеевич',
    birthYear: 1998,
    branchId: 3,
  ),
  Barber(
    id: 4,
    fullName: 'Васильев Илья Андреевич',
    birthYear: 1987,
    branchId: 1,
  ),
  Barber(
    id: 5,
    fullName: 'Морозов Кирилл Павлович',
    birthYear: 2000,
    branchId: 2,
  ),
  Barber(
    id: 6,
    fullName: 'Волков Тимур Русланович',
    birthYear: 1992,
    branchId: 3,
  ),
  Barber(
    id: 7,
    fullName: 'Соколов Никита Евгеньевич',
    birthYear: 1996,
    branchId: 1,
  ),
  Barber(
    id: 8,
    fullName: 'Лебедев Роман Алексеевич',
    birthYear: 1985,
    branchId: 2,
  ),
  Barber(
    id: 9,
    fullName: 'Новиков Егор Дмитриевич',
    birthYear: 2001,
    branchId: 3,
  ),
  Barber(
    id: 10,
    fullName: 'Фёдоров Глеб Викторович',
    birthYear: 1989,
    branchId: 1,
  ),
  Barber(
    id: 11,
    fullName: 'Михайлов Арсений Ильич',
    birthYear: 1997,
    branchId: 2,
  ),
];

const _names = [
  'Иванов Алексей Петрович',
  'Петров Сергей Николаевич',
  'Сидоров Дмитрий Андреевич',
  'Козлов Андрей Викторович',
  'Николаев Павел Олегович',
  'Орлов Виктор Сергеевич',
  'Захаров Михаил Ильич',
  'Белов Иван Константинович',
  'Тарасов Олег Владимирович',
  'Ефимов Георгий Романович',
  'Гусев Антон Евгеньевич',
  'Борисов Матвей Денисович',
  'Комаров Лев Артёмович',
  'Яковлев Фёдор Максимович',
  'Григорьев Степан Юрьевич',
  'Романов Вадим Игоревич',
  'Виноградов Ярослав Павлович',
  'Голубев Даниил Олегович',
  'Киселёв Руслан Тимурович',
  'Макаров Владислав Сергеевич',
  'Андреев Богдан Алексеевич',
  'Ковалёв Марк Андреевич',
  'Ильин Тимофей Викторович',
  'Зайцев Семён Дмитриевич',
  'Соловьёв Евгений Петрович',
  'Медведев Артур Николаевич',
  'Ершов Константин Ильич',
  'Никитин Роберт Эдуардович',
  'Фролов Игорь Валерьевич',
  'Блинов Савелий Маркович',
];

String _phone(int i) =>
    '+7 9${(10 + i * 3) % 90 + 10} ${(i * 37) % 900 + 100} '
    '${(i * 13) % 90 + 10} ${(i * 29) % 90 + 10}';

List<int> _services(int i) => i % 3 == 0 ? [i % 7 + 1, 3] : [i % 7 + 1];

int _price(List<int> ids) => ids
    .map((id) => seedServices.firstWhere((s) => s.id == id).price)
    .fold(0, (a, b) => a + b);

final seedAppointments = [
  for (var i = 0; i < _names.length; i++)
    Appointment(
      id: i + 1,
      clientName: _names[i],
      date: DateTime(
        2026,
        10 + i % 2,
        1 + (i * 7) % 30,
        10 + (i * 3) % 10,
        i.isEven ? 0 : 30,
      ),
      phone: _phone(i),
      serviceIds: _services(i),
      price: _price(_services(i)),
      barberId: i % 11 + 1,
    ),
];

final seedClients = [
  for (var i = 0; i < 12; i++)
    Client(
      id: i + 1,
      fullName: _names[i],
      phone: _phone(i),
      email: 'client${i + 1}@mail.ru',
      card: ClientCard(number: '${100001 + i * 17}', discount: (i % 4) * 5),
    ),
];
