import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminUser {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final String createdAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'student',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class AdminUsersNotifier extends StateNotifier<AsyncValue<List<AdminUser>>> {
  final String? token;
  // TODO: Use env config for url
  static const baseUrl = 'https://pythontutor-api.onrender.com/api/v1';

  AdminUsersNotifier(this.token) : super(const AsyncValue.loading()) {
    if (token != null) {
      fetchUsers();
    }
  }

  Future<void> fetchUsers() async {
    state = const AsyncValue.loading();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final users = data.map((e) => AdminUser.fromJson(e)).toList();
        state = AsyncValue.data(users);
      } else {
        state = AsyncValue.error('Failed to load users: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
    }
  }

  Future<void> toggleBlockStatus(String userId, bool currentStatus) async {
    if (token == null) return;
    
    final action = currentStatus ? 'block' : 'unblock';
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/$action'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Optimistically update UI
        if (state.hasValue) {
          final users = state.value!;
          final updatedUsers = users.map((u) {
            if (u.id == userId) {
              return AdminUser(
                id: u.id,
                email: u.email,
                fullName: u.fullName,
                role: u.role,
                isActive: !currentStatus,
                createdAt: u.createdAt,
              );
            }
            return u;
          }).toList();
          state = AsyncValue.data(updatedUsers);
        }
      } else {
        // Could show error snackbar
      }
    } catch (e) {
      // Handle error
    }
  }
}

final adminUsersProvider = StateNotifierProvider<AdminUsersNotifier, AsyncValue<List<AdminUser>>>((ref) {
  final authState = ref.watch(authProvider);
  return AdminUsersNotifier(authState.token);
});
