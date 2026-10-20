import 'result.dart';

export 'result.dart';

const operations = ['+', '-', '*', '/'];

CalcResult calculate(String? rawA, String? rawOp, String? rawB) {
  if (rawA == null || rawOp == null || rawB == null) {
    return const CalcFailure('Не хватает параметров: нужны a, оператор и b');
  }
  final a = parseNumber(rawA);
  final b = parseNumber(rawB);
  if (a == null || b == null) {
    return const CalcFailure('В адресе переданы не числа');
  }
  final double value;
  switch (rawOp) {
    case '+':
      value = a + b;
    case '-':
      value = a - b;
    case '*':
      value = a * b;
    case '/':
      if (b == 0) return const CalcFailure('Деление на ноль невозможно');
      value = a / b;
    default:
      return const CalcFailure('Неизвестная операция');
  }
  return CalcSuccess(
    '${formatNumber(a)} $rawOp ${formatNumber(b)} = ${formatNumber(value)}',
  );
}
