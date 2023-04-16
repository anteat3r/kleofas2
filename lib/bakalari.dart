import 'dart:convert';
import 'package:http/http.dart';
import 'package:result_type/result_type.dart';

Future<Result<String, String>> login (String url, String username, String password) async {
  if (url.isEmpty) {
    return Failure('fill url');
  }
  if (username.isEmpty) {
    return Failure('fill username');
  }
  if (password.isEmpty) {
    return Failure('fill password');
  }
  Uri? rqUri;
  if (url.contains('/')) {
    rqUri = Uri.https(url.split('/')[0], '${url.split('/')[1]}/api/login');
  } else {
    rqUri = Uri.https(url, '/api/login');
  }
  // Uri rqUri = Uri.parse('https://$url/api/login');
  Response response = await post(rqUri, body: "client_id=ANDR&grant_type=password&username=$username&password=$password", headers: {"Content-Type": "application/x-www-form-urlencoded"});
  if (response.statusCode == 200) {
    return Success(jsonDecode(response.body)['access_token']);
  }
  return Failure(response.body);
}

Future<Result<Map, String>> query (String url, String token, String endpoint, [Map<String, dynamic>? payload]) async {
  Uri? rqUri;
  if (url.contains('/')) {
    rqUri = Uri.https(url.split('/')[0], '${url.split('/')[1]}/api/3/$endpoint', payload);
  } else {
    rqUri = Uri.https(url, '/api/3/$endpoint', payload);
  }
  // Uri rqUri = Uri.parse('$url/api/3/$endpoint');
  Response response = await get(rqUri, headers: {"Content-Type": "application/x-www-form-urlencoded", "Authorization": "Bearer $token"});
  if (response.statusCode == 200) {
    return Success(jsonDecode(response.body));
  }
  return Failure(response.body);
}

Future<String> loginWebCookie (String url, String username, String password) async {
  Uri? rqUri;
  if (url.contains('/')) {
    rqUri = Uri.https(url.split('/')[0], '${url.split('/')[1]}/login');
  } else {
    rqUri = Uri.https(url, 'login');
  }
  Response resp = await get(rqUri);
  String sessionId = resp.headers['set-cookie']!.split(';')[0];
  if (url.contains('/')) {
    rqUri = Uri.https(url.split('/')[0], '${url.split('/')[1]}/Login');
  } else {
    rqUri = Uri.https(url, 'Login');
  }
  Response resp2 = await post(rqUri, headers: {'Cookie': sessionId}, body: {
    'username': username,
    'password': password,
    'returnUrl': ''
  });
  if (url.contains('/')) {
    rqUri = Uri.https(url.split('/')[0], '${url.split('/')[1]}/Timetable/Public/Actual/Class/ZX');
  } else {
    rqUri = Uri.https(url, 'Timetable/Public/Actual/Class/ZX');
  }
  String bakaAuth = resp2.headers['set-cookie']!.split(';')[0];
  return '$sessionId; $bakaAuth';
}

Future<String> queryWeb (String url, String endpoint, String cookie) async {
  Uri? rqUri;
  if (url.contains('/')) {
    rqUri = Uri.https(url.split('/')[0], '${url.split('/')[1]}/$endpoint');
  } else {
    rqUri = Uri.https(url, endpoint);
  }
  Response resp = await get(rqUri, headers: {
    'cookie': cookie
  });
  return resp.body;
}