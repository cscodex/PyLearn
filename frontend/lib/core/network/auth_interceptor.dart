import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Ref _ref;

  AuthInterceptor(this._dio, this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Handle token refresh
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken != null) {
        try {
          // Attempt to refresh token
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );
          
          if (response.statusCode == 200) {
            final newAccessToken = response.data['access_token'];
            final newRefreshToken = response.data['refresh_token'];
            
            await prefs.setString('access_token', newAccessToken);
            await prefs.setString('refresh_token', newRefreshToken);
            
            // Retry the original request
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';
            final cloneReq = await _dio.fetch(options);
            return handler.resolve(cloneReq);
          }
        } catch (e) {
          // Refresh failed, clear tokens and redirect to login
          await prefs.remove('access_token');
          await prefs.remove('refresh_token');
          // TODO: dispatch logout action to Riverpod/Router
        }
      }
    }
    
    return handler.next(err);
  }
}
