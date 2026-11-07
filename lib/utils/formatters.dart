String formatRupiah(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${value < 0 ? '-' : ''}Rp $buffer';
}

String formatPriceForInput(double price) {
  return price == price.roundToDouble()
      ? price.toInt().toString()
      : price.toString();
}
