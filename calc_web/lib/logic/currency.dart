import 'result.dart';

export 'result.dart';

const rates = <String, double>{
  'RUB': 1,
  'USD': 83.9,
  'EUR': 93.9,
  'KZT': 0.19,
  'AED': 22.8,
  'JPY': 0.53,
};

CalcResult convert(String? from, String? to, String? rawAmount) {
  if (from == null || to == null || rawAmount == null) {
    return const CalcFailure('Не хватает параметров: нужны from, to и amount');
  }
  final fromRate = rates[from];
  final toRate = rates[to];
  if (fromRate == null || toRate == null) {
    return const CalcFailure('Неизвестная валюта');
  }
  final amount = parseNumber(rawAmount);
  if (amount == null) {
    return const CalcFailure('Сумма не является числом');
  }
  if (amount < 0) {
    return const CalcFailure('Сумма не может быть отрицательной');
  }
  final value = amount * fromRate / toRate;
  return CalcSuccess('${formatNumber(amount)} $from = ${formatNumber(value)} $to');
}
