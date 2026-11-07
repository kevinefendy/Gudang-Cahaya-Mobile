import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  /// Android Emulator: http://10.0.2.2:3000/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  static const String _tokenKey = 'token';
  static const Duration _timeout = Duration(seconds: 20);

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
    
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Accept': 'application/json'};

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    if (auth) {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          'Sesi Anda sudah berakhir, silakan login kembali',
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body))
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          throw const ApiException('Method tidak didukung');
      }
      return _decode(response);
    } on TimeoutException {
      throw const ApiException(
        'Koneksi ke server terlalu lama, periksa jaringan Anda',
      );
    } on SocketException {
      throw ApiException(
        'Tidak dapat terhubung ke $baseUrl. Pastikan backend berjalan, '
        'HP dan PC satu jaringan, serta base URL sudah benar',
      );
    } on http.ClientException {
      throw ApiException(
        'Tidak dapat terhubung ke $baseUrl. Pastikan backend berjalan, '
        'HP dan PC satu jaringan, serta base URL sudah benar',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json = <String, dynamic>{};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      } on FormatException {
        json = <String, dynamic>{};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    final message = json['message']?.toString();
    throw ApiException(
      message?.isNotEmpty == true
          ? message!
          : 'Terjadi kesalahan (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic>? _jsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final json = await _request(
      'POST',
      '/auth/login',
      auth: false,
      body: {'email': email.trim(), 'password': password},
    );

    final data = _jsonMap(json['data']);
    final token = data?['token']?.toString();
    final user = _jsonMap(data?['user']);

    if (token == null || token.isEmpty || user == null) {
      throw const ApiException('Format respons login dari server tidak valid');
    }

    await _saveToken(token);
    return UserModel.fromJson(user);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _request(
      'POST',
      '/auth/register',
      auth: false,
      body: {
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
  }

  Future<UserModel> getCurrentUser() async {
    final json = await _request('GET', '/auth/me');
    final user = _jsonMap(json['user']);

    if (user == null) {
      throw const ApiException('Format data pengguna dari server tidak valid');
    }

    return UserModel.fromJson(user);
  }

  Future<UserModel> updateProfile({
    required String username,
    required String email,
    String currentPassword = '',
    String newPassword = '',
  }) async {
    final json = await _request(
      'PUT',
      '/auth/me',
      body: {
        'username': username.trim(),
        'email': email.trim(),
        if (currentPassword.isNotEmpty) 'currentPassword': currentPassword,
        if (newPassword.isNotEmpty) 'newPassword': newPassword,
      },
    );

    final user = _jsonMap(json['user']);

    if (user == null) {
      throw const ApiException('Format data pengguna dari server tidak valid');
    }

    return UserModel.fromJson(user);
  }

  Future<List<ProductModel>> getProducts() async {
    final json = await _request('GET', '/products');
    final data = json['data'];

    if (data is! List) {
      throw const ApiException('Format data produk dari server tidak valid');
    }

    return data
        .map((item) => _jsonMap(item))
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  Future<void> createProduct(
    ProductModel product, {
    String? imagePath,
  }) async {
    await _sendMultipart(
      'POST',
      '/products',
      product,
      imagePath: imagePath,
    );
  }

  Future<void> updateProduct(
    ProductModel product, {
    String? imagePath,
  }) async {
    await _sendMultipart(
      'PUT',
      '/products/${product.id}',
      product,
      imagePath: imagePath,
    );
  }

  Future<void> _sendMultipart(
    String method,
    String path,
    ProductModel product, {
    String? imagePath,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sesi Anda sudah berakhir, silakan login kembali',
        statusCode: 401,
      );
    }

    final request = http.MultipartRequest(method, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = product.name
      ..fields['category'] = product.category
      ..fields['price'] = product.price.toString()
      ..fields['stock'] = product.stock.toString()
      ..fields['description'] = product.description;

    try {
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed).timeout(_timeout);
      _decode(response);
    } on TimeoutException {
      throw const ApiException(
        'Koneksi ke server terlalu lama, periksa jaringan Anda',
      );
    } on SocketException {
      throw ApiException(
        'Tidak dapat terhubung ke $baseUrl. Pastikan backend berjalan, '
        'HP dan PC satu jaringan, serta base URL sudah benar',
      );
    } on http.ClientException {
      throw ApiException(
        'Tidak dapat terhubung ke $baseUrl. Pastikan backend berjalan, '
        'HP dan PC satu jaringan, serta base URL sudah benar',
      );
    } on FileSystemException {
      throw const ApiException('Gambar tidak dapat dibaca, coba pilih ulang');
    }
  }

  Future<void> deleteProduct(int id) async {
    await _request('DELETE', '/products/$id');
  }
}
