import 'models/common.dart';

typedef Validator = String? Function(String? value);

Validator all(List<Validator> validators) => (value) {
  for (final v in validators) {
    final error = v(value);
    if (error != null) return error;
  }
  return null;
};

String? notEmpty(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Обязательное поле' : null;

Validator maxLength(int max) =>
    (value) =>
        (value ?? '').trim().length > max ? 'Не длиннее $max символов' : null;

Validator minLength(int min) =>
    (value) =>
        (value ?? '').trim().length < min ? 'Не короче $min символов' : null;

Validator intRange(int min, int max) => (value) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null) return 'Введите целое число';
  if (n < min || n > max) return 'Допустимо от $min до $max';
  return null;
};

String? positiveInt(String? value) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null) return 'Введите целое число';
  if (n <= 0) return 'Значение должно быть больше нуля';
  return null;
}

final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

String? email(String? value) =>
    _emailRe.hasMatch((value ?? '').trim()) ? null : 'Неверный формат почты';

final _phoneRe = RegExp(r'^\+7[\d ]{10,14}$');

String? phone(String? value) {
  final v = (value ?? '').trim();
  final digits = v.replaceAll(RegExp(r'\D'), '');
  return _phoneRe.hasMatch(v) && digits.length == 11
      ? null
      : 'Формат: +7 999 123 45 67';
}

Validator digits(int count) =>
    (value) => RegExp('^\\d{$count}\$').hasMatch((value ?? '').trim())
    ? null
    : 'Нужно ровно $count цифр';

String? dateTime(String? value) =>
    parseUserDateTime(value ?? '') == null ? 'Формат: ДД.ММ.ГГГГ ЧЧ:ММ' : null;

Validator serverError(Map<String, String> errors, String field) =>
    (_) => errors[field];
