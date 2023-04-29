import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:result_type/result_type.dart';
import 'package:intl/intl.dart';
import 'package:html_unescape/html_unescape.dart';
import 'dart:math';
import 'package:flutter/services.dart';

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

Future<String> stravaLoginCookie (String zarizeni, String uzivatel, String heslo) async {
  Response resp = await get(Uri.parse('https://strava.cz/strava'));
  String viewstate = RegExp(r'<input type="hidden" name="__VIEWSTATE" id="__VIEWSTATE" value="(.*)" />')
    .firstMatch(resp.body)!.group(1) ?? 'idk';
  String viewstategenerator = RegExp(r'<input type="hidden" name="__VIEWSTATEGENERATOR" id="__VIEWSTATEGENERATOR" value="(.*)" />')
    .firstMatch(resp.body)!.group(1) ?? 'idk';
  String sessionId = resp.headers['set-cookie']!.split(';').first;
  String cookie = '$sessionId; zobrazeni=klasicke; tip=22; uzivatele=%5B%7B%22nazev%22%3A%22U%C5%BEivatel%201%22%2C%22jidelna%22%3A%22%22%2C%22jmeno%22%3A%22%22%7D%5D';
  String payload = '__VIEWSTATE=${Uri.encodeComponent(viewstate)}&__VIEWSTATEGENERATOR=${Uri.encodeComponent(viewstategenerator)}&zarizeni=$zarizeni&uzivatel=$uzivatel&heslo=$heslo&x=${Random().nextInt(100).toString()}&y=${Random().nextInt(50).toString()}';
  Response resp2 = await post(Uri.parse('https://strava.cz/strava/Stravnik/Prihlaseni'), headers: {
    "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    "accept-language": "en-US,en;q=0.7",
    "cache-control": "max-age=0",
    "content-type": "application/x-www-form-urlencoded",
    "sec-ch-ua": "\"Chromium\";v=\"112\", \"Brave\";v=\"112\", \"Not:A-Brand\";v=\"99\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "document",
    "sec-fetch-mode": "navigate",
    "sec-fetch-site": "same-origin",
    "sec-fetch-user": "?1",
    "sec-gpc": "1",
    "upgrade-insecure-requests": "1",
    "cookie": cookie,
    "Referer": "https://strava.cz/strava/Stravnik/Prihlaseni",
    'origin': 'https://strava.cz',
    "Referrer-Policy": "strict-origin-when-cross-origin"
  }, body: payload);
  String loginUrl = resp2.headers['location'] ?? 'idk';
  Request req = Request('GET', Uri.parse(loginUrl));
  req.headers.clear();
  req.headers.addAll({
    "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    "accept-language": "en-US,en;q=0.7",
    "cache-control": "max-age=0",
    "sec-ch-ua": "\"Chromium\";v=\"112\", \"Brave\";v=\"112\", \"Not:A-Brand\";v=\"99\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "document",
    "sec-fetch-mode": "navigate",
    "sec-fetch-site": "same-site",
    "sec-fetch-user": "?1",
    "sec-gpc": "1",
    "upgrade-insecure-requests": "1",
    "Referer": loginUrl,
    'origin': 'https://strava.cz/strava/Stravnik/Prihlaseni',
    'cookie': 'zobrazeni=klasicke; ObecneUpozorneni_$zarizeni.$uzivatel=kontrola; uzivatele=%5B%7B%22nazev%22%3A%22U%C5%BEivatel%201%22%2C%22jidelna%22%3A%22%22%2C%22jmeno%22%3A%22%22%7D%5D; tip=22; $sessionId'
  });
  req.followRedirects = false;
  StreamedResponse resp3 = await req.send();
  String? sessionId2 = resp3.headers['set-cookie'];
  assert(sessionId2 != null);
  return 'zarizeniJidelnicky=; jidelnicky_zarizeni=3753; JazykWebu=cs-CZ; zobrazeni=klasicke; ObecneUpozorneni_3753.kozlikrostislav=kontrola; uzivatele=%5B%7B%22nazev%22%3A%22U%C5%BEivatel%201%22%2C%22jidelna%22%3A%22%22%2C%22jmeno%22%3A%22%22%7D%5D; tip=22; $sessionId2 $sessionId';
}

Future<Map> loadStravaMenu (String cookie) async {
  Response resp4 = await get(Uri.parse('https://www.strava.cz/Strava5/Objednavky'), headers: {
    'cookie': cookie,
  });
  var unescape = HtmlUnescape();
  await Clipboard.setData(ClipboardData(text: RegExp(r'''<input type="hidden" name="datum" value="(\d\d\d\d-\d\d-\d\d)" \/>(?:\s|.)*?<div class="jidlo( objednane)?"?(?:\s|.)*?<input type="hidden" name="veta" value="(.*)"(?:\s|.)*?<div class="nazev sloupec (?:.*)\s*">(?<!Oběd )(.*)<\/div>''')
    .allMatches(resp4.body).map((e) => e.groups(List.generate(e.groupCount-1, (i) => i+1))).toString()));
  List rawList = RegExp(r'''<input type="hidden" name="datum" value="(\d\d\d\d-\d\d-\d\d)" \/>(?:\s|.)*?<div class="(.*?) sloupec\s*">(?:\s|.)*?(?:<div class="jidlo informacni-druh)?(?:\s|.)*?(?:<input type="hidden" name="veta" value=")?(.*)(?:\s|.)*?(?:<div class="nazev sloupec )?(?:.*)\s*(?:">)?(?<!Oběd )(.*)(?:<\/div>)?(?:\s|.)*?<div class="jidlo( objednane)?"?(?:\s|.)*?<input type="hidden" name="veta" value="(.*)"(?:\s|.)*?<div class="nazev sloupec (?:.*)\s*">(?<!Oběd )(.*)<\/div>(?:\s|.)*?<div class="jidlo( objednane)?"?(?:\s|.)*?<input type="hidden" name="veta" value="(.*)"(?:\s|.)*?<div class="nazev sloupec (?:.*)\s*">(?<!Oběd )(.*)<\/div>''')
    .allMatches(resp4.body).map((e) => [
      e.group(1) ?? '',
      e.group(2) == 'objednavani',
      e.group(3) != null,
      int.parse(e.group(4) ?? '69'),
      unescape.convert(e.group(5) ?? 'idk'),
      e.group(6) != null,
      int.parse(e.group(7) ?? '69'),
      unescape.convert(e.group(8) ?? 'idk'),
      e.group(9) != null,
      int.parse(e.group(10) ?? '69'),
      unescape.convert(e.group(11) ?? 'idk'),

      
      // e.group(2) == null ? false : true,
      // e.group(1) ?? '',
      // int.parse(e.group(3) ?? 'bruh'),
      // unescape.convert(e.group(4) ?? 'idk')
    ]).toList();
  String konto = RegExp(r'<span class="konto-hodnota">(\d+),00 Kč</span>').firstMatch(resp4.body)?.group(1) ?? 'idk';
  return {for (var e in rawList) e[0]: [e.sublist(2, 5), e.sublist(5, 8), e.sublist(8, 11), e[1]]}..addAll({'konto': konto});
  // return {for (var e in Set.from(rawList.map((e) => e[1]))) e: rawList.where((element) => element[1] == e).toList()}..addAll({'konto': konto});

}
Future<void> setLunch (String cookie, int veta, int amount) async {
  Response resp = await post(Uri.parse('https://www.strava.cz/Strava5/Objednavky/Prihlas'), headers: {
    'cookie': cookie
  }, body: '{"veta":$veta,"pocet":$amount}');
  print(resp.body);
  assert(resp.statusCode == 200);
}
Future<void> submitLunches (String cookie) async {
  Response resp = await post(Uri.parse('https://www.strava.cz/Strava5/Objednavky/Odesli'), headers: {
    'cookie': cookie
  });
  assert(resp.statusCode == 200);
}