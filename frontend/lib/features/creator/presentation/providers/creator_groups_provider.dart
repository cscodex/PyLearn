import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

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
      creatorId: json['creatorId'] ?? json['creator_id'] ?? '',
      memberCount: json['memberCount'] ?? json['member_count'] ?? 0,
    );
  }
}

class CreatorGroupsNotifier extends Notifier<AsyncValue<List<CreatorGroup>>> {
  Dio get _dio => ref.read(dioProvider);

  @override
  AsyncValue<List<CreatorGroup>> build() {
    fetchGroups();
    return const AsyncValue.loading();
  }

  Future<void> fetchGroups() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/creator/groups/');

      if (response.statusCode == 200) {
        final List data = response.data;
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
    try {
      final response = await _dio.post(
        '/creator/groups/',
        data: {'name': name},
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
    try {
      final response = await _dio.post(
        '/creator/groups/$groupId/users',
        data: {
          'email': email,
          'full_name': fullName,
          'password': password,
        },
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
    try {
      final response = await _dio.post(
        '/creator/groups/$groupId/assign',
        data: {
          'course_id': courseId,
          'assignment_type': isMandatory ? 'mandatory' : 'recommended',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteGroup(int groupId) async {
    try {
      final response = await _dio.delete('/creator/groups/$groupId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        fetchGroups();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateGroup(int groupId, String name) async {
    try {
      final response = await _dio.put(
        '/creator/groups/$groupId',
        data: {'name': name},
      );
      if (response.statusCode == 200) {
        fetchGroups();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addStudentsBulk(int groupId, List<String> userIds) async {
    try {
      final response = await _dio.post(
        '/creator/groups/$groupId/users/bulk',
        data: {'user_ids': userIds},
      );
      if (response.statusCode == 200) {
        fetchGroups();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> assignCoursesBulk(int groupId, List<int> courseIds, bool isMandatory) async {
    try {
      final response = await _dio.post(
        '/creator/groups/$groupId/assign/bulk',
        data: {
          'course_ids': courseIds,
          'assignment_type': isMandatory ? 'mandatory' : 'recommended',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchStudents(String query) async {
    try {
      final response = await _dio.get('/creator/groups/users/search', queryParameters: {'query': query});
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(int groupId) async {
    try {
      final response = await _dio.get('/creator/groups/$groupId/users');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> removeStudentFromGroup(int groupId, String userId) async {
    try {
      final response = await _dio.delete('/creator/groups/$groupId/members/$userId');
      if (response.statusCode == 200) {
        fetchGroups();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getGroupAssignments(int groupId) async {
    try {
      final response = await _dio.get('/creator/groups/$groupId/assignments');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final creatorGroupsProvider = NotifierProvider<CreatorGroupsNotifier, AsyncValue<List<CreatorGroup>>>(() {
  return CreatorGroupsNotifier();
});
