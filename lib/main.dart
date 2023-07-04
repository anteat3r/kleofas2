import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'homepage.dart';
import 'storage.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>('user');
  await Hive.openBox<Map>('storage');
  await Hive.openBox<int>('refresh');
  await Hive.openBox<Map>('passwords');
  await Hive.openBox<Map>('log');
  await Hive.openBox<Map>('snacks');
  if (Platform.isAndroid || Platform.isIOS) {
    Workmanager().initialize(callbackDispatcher);
    Workmanager().registerPeriodicTask(
      'bgrefresh', 'backgroundRefreshing',
      frequency: Duration(minutes: int.tryParse(user.get("notifdur") ?? "15") ?? 15),
      constraints: Constraints(networkType: NetworkType.connected)
    );
  }
  runApp(MyApp(navigatorKey));
}

@pragma('vm:entry-point')
void callbackDispatcher () {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    await Hive.openBox<Map>('log');
    await Hive.openBox<String>('user');
    await Hive.openBox<Map>('storage');
    await Hive.openBox<int>('refresh');
    await Hive.openBox<Map>('passwords');
    await Hive.openBox<Map>('snacks');
    await logInfo(['bg loading started']);
    try {
      await bgLoad();
    } catch (e, s) {
      await logError(['bg loading crashed', e, s]);
    }
    await logInfo(['bg loading finished']);
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const MyApp(this.navigatorKey, {super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Kleofáš',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.lightBlue,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
