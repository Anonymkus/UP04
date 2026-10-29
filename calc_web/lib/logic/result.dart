sealed class CalcResult {
  const CalcResult();
}

class CalcSuccess extends CalcResult {
  final String text;
  const CalcSuccess(this.text);
}

class CalcFailure extends CalcResult {
  final String message;
  const CalcFailure(this.message);
}

double? parseNumber(String? raw) {
  if (raw == null) return null;
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite) return null;
  return value;
}

String formatNumber(double value) {
  var s = value.toStringAsFixed(6);
  s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return s == '-0' ? '0' : s;
}
