import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:remedi_base/remedi_base.dart';

import '../errors/app_error.dart';

abstract class DioApiService<R extends dynamic> extends IApiService
    with _TransFormer<R> {
  DioApiService({required IClientBuilder clientBuilder})
      : super(clientBuilder: clientBuilder);

  @override
  Future<dynamic> requestPost(
      {String? path,
      dynamic data,
      Map<String, dynamic>? query,
      Function(dynamic)? onSuccess,
      Function(dynamic)? onFail,
      Function(dynamic)? onError}) async {
    return handleResponse(
        await clientBuilder.post(
          path,
          data: data,
          query: query,
        ),
        onSuccess: onSuccess,
        onError: onError,
        onFail: onFail);
  }

  @override
  Future<dynamic> requestGet(
      {String? path,
      dynamic data,
      Map<String, dynamic>? query,
      Function(dynamic)? onSuccess,
      Function(dynamic)? onFail,
      Function(dynamic)? onError}) async {
    return handleResponse(
        await clientBuilder.get(
          path,
          query: query,
        ),
        onSuccess: onSuccess,
        onError: onError,
        onFail: onFail);
  }

  @override
  Future<dynamic> requestPatch(
      {String? path,
      dynamic data,
      Map<String, dynamic>? query,
      Function(dynamic)? onSuccess,
      Function(dynamic)? onFail,
      Function(dynamic)? onError}) async {
    return handleResponse(
        await clientBuilder.patch(
          path,
          data: data,
          query: query,
        ),
        onSuccess: onSuccess,
        onError: onError,
        onFail: onFail);
  }

  @override
  Future<dynamic> requestDelete(
      {String? path,
      dynamic data,
      Map<String, dynamic>? query,
      Function(dynamic)? onSuccess,
      Function(dynamic)? onFail,
      Function(dynamic)? onError}) async {
    return handleResponse(
        await clientBuilder.delete(
          path,
          data: data,
          query: query,
        ),
        onSuccess: onSuccess,
        onError: onError,
        onFail: onFail);
  }

  @override
  Future<dynamic> requestUpload({
    required String filePath,
    dynamic data,
    Function(dynamic)? onSuccess,
    Function(dynamic)? onFail,
    Function(dynamic)? onError,
  }) async {
    var formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    return handleResponse(
        await clientBuilder.upload(
          path,
          data: formData,
        ),
        onSuccess: onSuccess,
        onError: onError,
        onFail: onFail);
  }

  @override
  Future<dynamic> requestDownload({
    required String urlPath,
    required String savePath,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await clientBuilder.download(
      urlPath,
      savePath,
      data: data,
      queryParameters: queryParameters,
    );
  }
}

abstract class _TransFormer<R> {
  /// json should be map<string,dynamic> or int, string, bool
  R jsonToObject(dynamic json);

  dynamic handleResponse(
    Response? res, {
    Function(dynamic)? onSuccess,
    Function(dynamic)? onFail,
    Function(dynamic)? onError,
  }) {
    if (res == null) {
      if (onFail != null) onFail(res);
      return AppError(
          code: "FAIL",
          message: "response is null",
          title: "FAIL",
          body: "response is null");
    }

    if (!"${res.statusCode}".startsWith("20")) {
      if (onError != null) onError(res);
      return AppError(
          code: "${res.statusCode}",
          message: res.data == null ? null : "${res.data}",
          title: res.statusMessage,
          body: res.data);
    }

    if (onSuccess != null) {
      onSuccess(res);
    }

    if (res.statusCode == 204) {
      return null;
    }

    // support json as String
    if (res.data is String) {
      return res.data;
    }

    // support json as bool
    if (res.data is bool) {
      return res.data;
    }

    // 204(no-content) code - response data is null
    if (res.data == null) {
      return res.data;
    }

    return jsonToObject(res.data);
  }
}

class DioBuilder extends IClientBuilder {
  final String baseUrl;
  final bool enableLogging;
  final String? userAgent;
  final String? appVersion;
  final String? osVersion;
  final String? appId;
  final List<Interceptor>? authHeaderInterceptors;
  final List<Interceptor>? interceptors;
  final Map<String, dynamic>? otherHeaders;

  // final bool enableFirebasePerformance;

  DioBuilder._(
    this.baseUrl, {
    this.enableLogging = false,
    this.userAgent,
    this.appVersion,
    this.osVersion,
    this.appId,
    this.authHeaderInterceptors,
    this.interceptors,
    this.otherHeaders,
  }) : super(baseUrl: baseUrl);

  factory DioBuilder.auth(
    String baseUrl, {
    bool enableLogging = false,
    required String userAgent,
    required String? appVersion,
    required String? osVersion,
    required String? appId,
    required List<Interceptor> authHeaderInterceptors,
    List<Interceptor>? interceptors,
    Map<String, dynamic>? otherHeaders,
  }) =>
      DioBuilder._(
        baseUrl,
        enableLogging: enableLogging,
        userAgent: userAgent,
        appVersion: appVersion,
        osVersion: osVersion,
        appId: appId,
        authHeaderInterceptors: authHeaderInterceptors,
        interceptors: interceptors,
        otherHeaders: otherHeaders,
      );

  factory DioBuilder.noneAuth(
    String baseUrl, {
    bool enableLogging = false,
    required String userAgent,
    required String? appVersion,
    required String? osVersion,
    required String? appId,
    List<Interceptor>? interceptors,
    Map<String, dynamic>? otherHeaders,
  }) =>
      DioBuilder._(
        baseUrl,
        enableLogging: enableLogging,
        userAgent: userAgent,
        appVersion: appVersion,
        osVersion: osVersion,
        appId: appId,
        interceptors: interceptors,
        otherHeaders: otherHeaders,
      );

  @override
  Dio build() {
    Dio http = Dio();
    http.options.baseUrl = baseUrl;
    http.options.connectTimeout = 15000;
    if (otherHeaders?.isNotEmpty ?? false) {
      http.options.headers.addAll(otherHeaders!);
    }
    if (userAgent != null)
      http.options.headers.addAll({'User-Agent': userAgent});
    if (appVersion != null)
      http.options.headers.addAll({'App-Version': appVersion});
    if (osVersion != null)
      http.options.headers.addAll({'Os-Version': osVersion});
    if (appId != null) http.options.headers.addAll({'App-Id': appId});
    http.options.headers.addAll({'Accept': 'application/json'});

    http.transformer = FlutterTransformer();

    http.interceptors.add(LogInterceptor(
        request: enableLogging,
        requestBody: enableLogging,
        responseBody: enableLogging,
        requestHeader: enableLogging,
        responseHeader: enableLogging));

    authHeaderInterceptors?.forEach((Interceptor interceptor) {
      http.interceptors.add(interceptor);
    });

    interceptors?.forEach((Interceptor interceptor) {
      http.interceptors.add(interceptor);
    });
    return http;
  }

  @override
  Future<dynamic> delete(
    String? path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    var res;
    try {
      res = await build().delete<dynamic>(path ?? "",
          data: _data(data), queryParameters: query);
    } catch (e) {
      if (e is DioError) {
        res = e.response;
      } else {
        res = e;
      }
    }
    return res;
  }

  @override
  Future<dynamic> get(
    String? path, {
    Map<String, dynamic>? query,
  }) async {
    var res;
    try {
      res = await build().get<dynamic>(path ?? "", queryParameters: query);
    } catch (e) {
      if (e is DioError) {
        res = e.response;
      } else {
        res = e;
      }
    }
    return res;
  }

  @override
  Future<dynamic> patch(
    String? path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    var res;
    try {
      res = await build().patch<dynamic>(path ?? "",
          data: _data(data), queryParameters: query);
    } catch (e) {
      if (e is DioError) {
        res = e.response;
      } else {
        res = e;
      }
    }

    return res;
  }

  @override
  Future<dynamic> post(
    String? path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    var res;
    try {
      res = await build()
          .post<dynamic>(path ?? "", data: _data(data), queryParameters: query);
    } catch (e) {
      if (e is DioError) {
        res = e.response;
      } else {
        res = e;
      }
    }

    return res;
  }

  @override
  Future<dynamic> download(String urlPath, savePath,
      {Map<String, dynamic>? queryParameters, data}) async {
    return await build().download(urlPath, savePath,
        queryParameters: queryParameters, data: data);
  }

  @override
  Future<dynamic> upload(String path, {dynamic data}) async {
    return await build().post(path, data: data);
  }

  dynamic _data(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is int) {
      return data;
    }

    if (data is String) {
      return data;
    }

    if (data is bool) {
      return data;
    }

    if (data is IDto) {
      return data.toJson;
    }

    assert(false);
  }
}

class FlutterTransformer extends DefaultTransformer {
  FlutterTransformer() : super(jsonDecodeCallback: _parseJson);
}

// Must be top-level function
_parseAndDecode(String response) {
  return jsonDecode(response);
}

_parseJson(String text) {
  return compute(_parseAndDecode, text);
}

class AuthHeaderInterceptor extends Interceptor {
  final Future<String?> token;

  AuthHeaderInterceptor(this.token);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers.addAll({
      "Authorization": "Bearer ${await token}",
    });
    return super.onRequest(options, handler);
  }
}
