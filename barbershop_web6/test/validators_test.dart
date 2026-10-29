import 'package:barbershop_web/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('обязательное поле отклоняет пустую строку и пробелы', () {
    expect(notEmpty(''), isNotNull);
    expect(notEmpty('   '), isNotNull);
    expect(notEmpty('Стрижка'), isNull);
  });

  test('почта проверяется по формату', () {
    expect(email('client1@mail.ru'), isNull);
    expect(email('client1mail.ru'), isNotNull);
    expect(email('client1@'), isNotNull);
  });

  test('телефон принимается только в формате +7 и 11 цифр', () {
    expect(phone('+7 999 123 45 67'), isNull);
    expect(phone('8 999 123 45 67'), isNotNull);
    expect(phone('+7 999'), isNotNull);
  });

  test('надёжный пароль: длина, цифра и специальный символ', () {
    expect(strongPassword('abc1!'), isNotNull);
    expect(strongPassword('abcdefgh!'), isNotNull);
    expect(strongPassword('abcdefgh1'), isNotNull);
    expect(strongPassword('abcdefg1!'), isNull);
  });

  test('диапазон чисел и проверка формата даты', () {
    expect(intRange(1, 10)('5'), isNull);
    expect(intRange(1, 10)('11'), isNotNull);
    expect(intRange(1, 10)('пять'), isNotNull);
    expect(dateTime('25.10.2026 18:00'), isNull);
    expect(dateTime('2026-10-25'), isNotNull);
  });
}
