import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../utils/storage_util.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageUtil.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
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
}
