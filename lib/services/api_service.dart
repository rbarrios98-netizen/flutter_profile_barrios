import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl;
  ApiService({this.baseUrl = 'http://localhost:3000'});

  Future<Map<String, String>> _headers() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await AuthService().getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Project>> fetchProjects() async {
    final res = await http.get(
      Uri.parse('$baseUrl/projects'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load projects: ${res.statusCode}');
  }

  Future<Project> createProject(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Project.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create project: ${res.statusCode}');
  }

  Future<String> classifyProject(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/classify'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['domain'] as String? ?? 'Other';
    }
    throw Exception('Failed to classify: ${res.statusCode}');
  }

  Future<List<dynamic>> fetchUsers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data;
    }
    throw Exception('Failed to load users: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/schedules'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create schedule: ${res.statusCode}');
  }

  Future<List<dynamic>> fetchSchedules({String? student}) async {
    final uri = (student != null && student.isNotEmpty)
        ? Uri.parse(
            '$baseUrl/schedules?student=${Uri.encodeComponent(student)}',
          )
        : Uri.parse('$baseUrl/schedules');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data;
    }
    throw Exception('Failed to load schedules: ${res.statusCode}');
  }
}
