import 'dart:convert';
import 'package:http/http.dart';
import 'package:result_type/result_type.dart';
import 'package:html_unescape/html_unescape.dart';
import 'dart:math';
import 'package:html/dom.dart';

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
  Response response = await get(rqUri, headers: {"Content-Type": "application/x-www-form-urlencoded", "Authorization": "Bearer $token"});
  if (response.statusCode == 200) {
    return Success(jsonDecode(response.body));
  }
  return Failure(response.body);
}

Future<Result<Map, String>> postJsonQuery (String url, String token, String endpoint, {Map<String, dynamic>? payload, Object? body}) async {
  Uri? rqUri;
  if (url.contains('/')) {
    rqUri = Uri.https(url.split('/')[0], '${url.split('/')[1]}/api/3/$endpoint', payload);
  } else {
    rqUri = Uri.https(url, '/api/3/$endpoint', payload);
  }
  Response response = await post(rqUri, headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode(body));
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
  String? loginUrl = resp2.headers['location'];
  assert(loginUrl != null);
  Request req = Request('GET', Uri.parse(loginUrl ?? 'bruh'));
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
    "Referer": loginUrl ?? 'bruh',
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
  String konto = RegExp(r'<span class="konto-hodnota">(\d+),00 Kč</span>').firstMatch(resp4.body)?.group(1) ?? 'idk';
  List<String> objednavky = resp4.body.split('<div class="objednavka">').sublist(1);
  return { for (var element in objednavky.map((e) {
    if (e.contains('informacni-druh')) {
      String? date = RegExp(r'''<input type="hidden" name="datum" value="(\d\d\d\d-\d\d-\d\d)" \/>''').firstMatch(e)!.group(1);
      assert(date != null);
      bool enabled = RegExp(r'''<div class="datum sloupec .+?">.*?</div>''').hasMatch(e);
      List<int> vetas = RegExp(r'''<input type="hidden" name="veta" value="(.*)" \/>''').allMatches(e).map((e2) => int.parse(e2.group(1) ?? 'bruh')).toList();
      List<String> titles = RegExp(r'''<div class="nazev sloupec nevybratelne\s*">(.+?)</div>''').allMatches(e).map((e2) => e2.group(1) ?? '').toList();
      List<bool> checks = RegExp(r'''<input type="hidden" value="(.+?)" autocomplete="off" \/>''').allMatches(e).map((e2) => e2.group(1) == 'zaskrtnuto').toList();
      return {
        'date': date,
        'checks': checks,
        'enabled': enabled,
        'soup': unescape.convert(titles.first),
        'first': {
          'ordered': checks[enabled ? 2 : 1],
          'veta': vetas[1],
          'title': unescape.convert(titles[1]),
        },
        'second': {
          'ordered': checks[enabled ? 3 : 2],
          'veta': vetas[2],
          'title': unescape.convert(titles[2]),
        },
      };
    } else {
      String? date = RegExp(r'''<input type="hidden" name="datum" value="(\d\d\d\d-\d\d-\d\d)" \/>''').firstMatch(e)!.group(1);
      assert(date != null);
      String title = RegExp(r'''<div class="nazev sloupec nevybratelne\s*">(.+?)</div>''').firstMatch(e)!.group(1) ?? 'idk';
      return {
        'date': date,
        'enabled': false,
        'soup': unescape.convert(title),
        'first': {
          'ordered': false,
          'veta': 69,
          'title': unescape.convert(title),
        },
        'second': {
          'ordered': false,
          'veta': 69,
          'title': unescape.convert(title),
        },
      };
    }
  })) element['date'] : element..removeWhere((key, value) => key == 'date')}..addAll({'konto': konto});
}

Future<void> setLunch (String cookie, int veta, int amount) async {
  Response resp = await post(Uri.parse('https://www.strava.cz/Strava5/Objednavky/Prihlas'), headers: {
    'cookie': cookie,
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.5",
    "content-type": "application/json",
    "sec-ch-ua": "\"Chromium\";v=\"112\", \"Brave\";v=\"112\", \"Not:A-Brand\";v=\"99\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "sec-gpc": "1",
    "x-requested-with": "XMLHttpRequest",
    "Referer": "https://www.strava.cz/Strava5/Objednavky",
    "Referrer-Policy": "strict-origin-when-cross-origin"
  }, body: '{"veta":$veta,"pocet":$amount}');
  assert(resp.statusCode == 200);
}

Future<void> submitLunches (String cookie) async {
  Response resp = await post(Uri.parse('https://www.strava.cz/Strava5/Objednavky/Odesli'), headers: {
    'cookie': cookie,
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.5",
    "content-type": "application/json",
    "sec-ch-ua": "\"Chromium\";v=\"112\", \"Brave\";v=\"112\", \"Not:A-Brand\";v=\"99\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "sec-gpc": "1",
    "x-requested-with": "XMLHttpRequest",
    "Referer": "https://www.strava.cz/Strava5/Objednavky",
    "Referrer-Policy": "strict-origin-when-cross-origin"
  });
  assert(resp.statusCode == 200);
}

extension Flatten<T> on List<List<T>> {
  List<T> flatten() => expand((element) => element).toList();
}

extension EmptyChildren on Element {
  List<Element> getEmptyChildren() {
    return children.map((e) => e.children.isEmpty ? [e] : e.getEmptyChildren()).toList().flatten();
  }
}

enum CellColor { white, pink, green }

typedef Cell = ({
  String subject,
  String teacher,
  String room,
  String group,
  CellColor color,
});

typedef TimeTable = List<List<List<Cell>>>;

TimeTable parseTimetable(Document html) => 
  html
  .querySelector(".bk-timetable-main")!
  .querySelectorAll(".bk-timetable-row")
  .map((e) => e.querySelectorAll(".bk-timetable-cell").map((d) => d.querySelectorAll(".day-item-hover").map((f) => (
    room: f.querySelector(".right > div")?.innerHtml ?? "",
    group: f.querySelector(".left > div")?.innerHtml ?? "",
    subject: f.querySelector(".middle")?.innerHtml.trim() ?? "",
    teacher: f.querySelector(".bottom > span")?.innerHtml.trim() ?? "",
    color: f.classes.contains("pink")
      ? CellColor.pink
      : f.classes.contains("green")
        ? CellColor.green
        : CellColor.white
  )).toList()).toList()).toList();

typedef BakalariIds = ({
  Map<String, String> classes,
  Map<String, String> teachers,
  Map<String, String> rooms,
});

BakalariIds convertBakalariIds(Map ids) => (
  classes: ids["classes"]!,
  teachers: ids["teachers"]!,
  rooms: ids["rooms"]
);

BakalariIds parseBakalariIds(Document html) => 
  convertBakalariIds({"classes": "Class", "teachers": "Teacher", "rooms": "Room"}.map((key, value) => MapEntry(
    key, {for (final e in html.querySelector("#selected$value")!.children.where(
      (f) => f.attributes.containsKey("value")))
    e.attributes["value"]!: e.innerHtml.trim()} 
  )));
