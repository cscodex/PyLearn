import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../auth/presentation/providers/auth_provider.dart';

class CreatorGroup {
  final int id;
  final String name;
  final String creatorId;
  final int memberCount;

  CreatorGroup({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.memberCount,
  });

  factory CreatorGroup.fromJson(Map<String, dynamic> json) {
    return CreatorGroup(
      id: json['id'],
      name: json['name'],
      creatorId: json['creatorId'] ?? '',
      memberCount: json['memberCount'] ?? 0,
    );
  }
}

class CreatorGroupsNotifier extends StateNotifier<AsyncValue<List<CreatorGroup>>> {
  final String? token;
  static const baseUrl = 'https://pythontutor-api.onrender.com/api/v1';

  CreatorGroupsNotifier(this.token) : super(const AsyncValue.loading()) {
    if (token != null) {
      fetchGroups();
    }
  }

  Future<void> fetchGroups() async {
    state = const AsyncValue.loading();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/creator/groups/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final groups = data.map((e) => CreatorGroup.fromJson(e)).toList();
        state = AsyncValue.data(groups);
      } else {
        state = AsyncValue.error('Failed to load groups', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
    }
  }

  Future<bool> createGroup(String name) async {
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/creator/groups/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        fetchGroups(); // Refresh
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addStudentToGroup(int groupId, String email, String fullName, String password) async {
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/creator/groups/$groupId/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'fullName': fullName,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        fetchGroups(); // Refresh to update member count
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> assignCourse(int groupId, int courseId, bool isMandatory) async {
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/creator/groups/$groupId/assign'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'courseId': courseId,
          'assignmentType': isMandatory ? 'mandatory' : 'recommended',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

final creatorGroupsProvider = StateNotifierProvider<CreatorGroupsNotifier, AsyncValue<List<CreatorGroup>>>((ref) {
  final authState = ref.watch(authProvider);
  return CreatorGroupsNotifier(authState.token);
});
