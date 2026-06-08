import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

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
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      role: json['role'] ?? 'student',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] ?? json['created_at'] ?? '',
    );
  }
}

class AdminUsersNotifier extends Notifier<AsyncValue<List<AdminUser>>> {
  Dio get _dio => ref.read(dioProvider);

  @override
  AsyncValue<List<AdminUser>> build() {
    fetchUsers();
    return const AsyncValue.loading();
  }

  Future<void> fetchUsers() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/admin/users');

      if (response.statusCode == 200) {
        final List data = response.data;
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
    final action = currentStatus ? 'block' : 'unblock';
    try {
      final response = await _dio.put('/admin/users/$userId/$action');

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
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final response = await _dio.delete('/admin/users/$userId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (state.hasValue) {
          final users = state.value!;
          state = AsyncValue.data(users.where((u) => u.id != userId).toList());
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateUser(String userId, String email, String fullName, String role) async {
    try {
      final response = await _dio.put(
        '/admin/users/$userId',
        data: {
          'email': email,
          'full_name': fullName,
          'role': role,
        },
      );
      if (response.statusCode == 200) {
        if (state.hasValue) {
          final users = state.value!;
          final updatedUsers = users.map((u) {
            if (u.id == userId) {
              return AdminUser(
                id: u.id,
                email: email,
                fullName: fullName,
                role: role,
                isActive: u.isActive,
                createdAt: u.createdAt,
              );
            }
            return u;
          }).toList();
          state = AsyncValue.data(updatedUsers);
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> createUser(String email, String fullName, String password, String role) async {
    try {
      final response = await _dio.post(
        '/admin/users',
        data: {
          'email': email,
          'full_name': fullName,
          'password': password,
          'role': role,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final newUser = AdminUser.fromJson(response.data);
        if (state.hasValue) {
          final users = state.value!;
          state = AsyncValue.data([...users, newUser]);
        } else {
          state = AsyncValue.data([newUser]);
        }
      }
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }
}

final adminUsersProvider = NotifierProvider<AdminUsersNotifier, AsyncValue<List<AdminUser>>>(() {
  return AdminUsersNotifier();
});
