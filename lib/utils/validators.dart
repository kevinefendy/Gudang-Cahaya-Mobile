const int minPasswordLength = 8;

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email wajib diisi';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Format email tidak valid';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Password wajib diisi';
  if (password.length < minPasswordLength) {
    return 'Password minimal $minPasswordLength karakter';
  }
  return null;
}

String? validateUsername(String? value) {
  final username = value?.trim() ?? '';
  if (username.isEmpty) return 'Username wajib diisi';
  if (username.length < 3) return 'Username minimal 3 karakter';
  return null;
}

String? validateRequired(String? value, String label) {
  if ((value?.trim() ?? '').isEmpty) return '$label wajib diisi';
  return null;
}

double? parsePriceInput(String value) {
  final text = value.trim().replaceAll('Rp', '').replaceAll(' ', '');
  if (text.isEmpty) return null;
  final normalized = text.contains(',')
      ? text.replaceAll('.', '').replaceAll(',', '.')
      : text;
  return double.tryParse(normalized);
}

int? parseIntInput(String value) {
  final text = value.trim().replaceAll(' ', '');
  if (text.isEmpty) return null;
  return int.tryParse(text);
}

String? validatePrice(String? value) {
  if ((value?.trim() ?? '').isEmpty) return 'Harga wajib diisi';
  final price = parsePriceInput(value ?? '');
  if (price == null) return 'Harga harus berupa angka';
  if (price <= 0) return 'Harga harus lebih dari 0';
  return null;
}

String? validateStock(String? value) {
  if ((value?.trim() ?? '').isEmpty) return 'Stok wajib diisi';
  final stock = parseIntInput(value ?? '');
  if (stock == null) return 'Stok harus berupa angka';
  if (stock < 0) return 'Stok tidak boleh negatif';
  return null;
}
