import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  //10.0.2.2 localhost 192.168.1.67
  static const String baseUrl = 'http://192.168.1.67:3000/api/v1';

  Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user': {'first_name': firstName, 'last_name': lastName, 'email': email, 'password': password}}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await _saveToken(data['token']);
      return {'success': true, 'user': data['user']};
    } else {
      return {'success': false, 'error': (data['errors'] as List?)?.join(', ') ?? 'Signup failed'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await _saveToken(data['token']);
      return {'success': true, 'user': data['user']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Login failed'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'error': 'Not authorized'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'user': data};
    } else {
      return {'success': false, 'error': (data['errors'] as List?)?.join(', ') ?? 'Chyba pri ukladaní'};
    }
  }

  Future<List<dynamic>> getInvoices() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/invoices'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  Future<List<dynamic>> getCompanies() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/companies'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<Map<String, dynamic>> createCompany(Map<String, dynamic> body) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/companies'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return {'success': true, 'company': data};
    return {'success': false, 'error': (data['errors'] as List?)?.join(', ') ?? 'Chyba'};
  }

  Future<Map<String, dynamic>> updateCompany(int id, Map<String, dynamic> body) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/companies/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return {'success': true, 'company': data};
    return {'success': false, 'error': (data['errors'] as List?)?.join(', ') ?? 'Chyba'};
  }

  Future<bool> deleteInvoice(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/invoices/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  Future<bool> cancelInvoice(int id) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/invoices/$id/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getInvoiceHistory(int id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/invoices/$id/history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>> getInvoice(int id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/invoices/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'invoice': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': 'Faktúra nenájdená'};
    }
  }

  Future<Map<String, dynamic>> updateInvoice(int id, Map<String, dynamic> body) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/invoices/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'invoice': data};
    } else {
      return {'success': false, 'error': (data['errors'] as List?)?.join(', ') ?? 'Chyba pri ukladaní'};
    }
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> body) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/invoices'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {'success': true, 'invoice': data};
    } else {
      return {'success': false, 'error': (data['errors'] as List?)?.join(', ') ?? 'Chyba pri ukladaní'};
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
}