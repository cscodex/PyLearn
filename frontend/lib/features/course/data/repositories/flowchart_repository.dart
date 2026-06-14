import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/flowchart.dart';

final flowchartRepositoryProvider = Provider<FlowchartRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FlowchartRepository(dio);
});

final savedFlowchartsProvider = FutureProvider.autoDispose<List<SavedFlowchart>>((ref) async {
  final repository = ref.watch(flowchartRepositoryProvider);
  return repository.getSavedFlowcharts();
});

class FlowchartRepository {
  final Dio _dio;

  FlowchartRepository(this._dio);

  Future<List<SavedFlowchart>> getSavedFlowcharts() async {
    try {
      final response = await _dio.get('/flowcharts/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SavedFlowchart.fromJson(json)).toList();
      }
      throw Exception('Failed to load flowcharts');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<SavedFlowchart> saveFlowchart(String title, List<FlowchartNode> nodes, List<FlowchartEdge> edges) async {
    try {
      final response = await _dio.post(
        '/flowcharts/',
        data: {
          'title': title,
          'nodes': nodes.map((n) => n.toJson()).toList(),
          'edges': edges.map((e) => e.toJson()).toList(),
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SavedFlowchart.fromJson(response.data);
      }
      throw Exception('Failed to save flowchart');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to save flowchart');
      }
      throw Exception('Network error: $e');
    }
  }

  Future<void> updateFlowchart(int id, String title, List<FlowchartNode> nodes, List<FlowchartEdge> edges) async {
    try {
      final response = await _dio.put(
        '/flowcharts/$id',
        data: {
          'title': title,
          'nodes': nodes.map((n) => n.toJson()).toList(),
          'edges': edges.map((e) => e.toJson()).toList(),
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update flowchart');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteFlowchart(int id) async {
    try {
      await _dio.delete('/flowcharts/$id');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
