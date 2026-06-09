import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  // Use String.fromEnvironment to allow passing the URL during build/run:
  // flutter run --dart-define=API_URL=https://your-render-url.onrender.com/api/v1
  const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://pythontutor-api.onrender.com/api/v1', // Fallback to Render
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(dio, ref));

  return dio;
});
