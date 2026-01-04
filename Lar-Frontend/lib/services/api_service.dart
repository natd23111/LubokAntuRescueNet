import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../utils/storage_util.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      validateStatus: (status) {
        // Only throw on 500+ errors, allow redirects to be handled
        return status != null && status < 500;
      },
    ),
  );

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageUtil.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          print('API Error: ${error.message}');
          print('Status Code: ${error.response?.statusCode}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    return _dio.post(endpoint, data: data);
  }

  Future<Response> get(String endpoint) async {
    return _dio.get(endpoint);
  }

  Future<Response> put(String endpoint, Map<String, dynamic> data) async {
    return _dio.put(endpoint, data: data);
  }

  Future<Response> delete(String endpoint) async {
    return _dio.delete(endpoint);
  }

  Future<Response> patch(String endpoint, Map<String, dynamic> data) async {
    return _dio.patch(endpoint, data: data);
  }
}
