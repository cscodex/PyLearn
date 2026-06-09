import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/certificate.dart';

final myCertificatesProvider = FutureProvider.autoDispose<List<Certificate>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/certificates/me');
  return (response.data as List).map((json) => Certificate.fromJson(json)).toList();
});

final allCertificatesProvider = FutureProvider.autoDispose<List<Certificate>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/certificates/all');
  return (response.data as List).map((json) => Certificate.fromJson(json)).toList();
});
