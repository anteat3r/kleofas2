import 'package:flutter/material.dart';
import 'storage.dart';
import 'dart:io';
import 'dart:async';

class QrPage extends StatefulWidget {
  const QrPage({Key? key}) : super(key: key);
  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {

  Timer? _timer;

  @override
  void initState () {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {setState(() {});});
  }

  @override
  void dispose () {
    super.dispose();
    _timer?.cancel();
  }

  String renderDuration(Duration dur) {
    String hours = "";
    String minutes = "";
    int seconds = dur.inSeconds;
    if (seconds > 3600) {
      hours = "${seconds ~/ 3600} h ";
      seconds %= 3600;
    }
    if (seconds > 60) {
      minutes = "${seconds ~/ 60} m ";
      seconds %= 60;
    }
    return "$hours$minutes${seconds} s";
  }

  @override
  Widget build (BuildContext context) {
    final now = DateTime.now();
    Duration diff = DateTime(now.year, now.month, now.day, 20, 56, 0, 0, 0).difference(now);
    diff = Duration(hours: diff.inHours, minutes: diff.inMinutes, seconds: diff.inSeconds);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Qr kód"),
      ),
      body: Column(
        children: [
          if ((user.get("qrpath") ?? "").isNotEmpty) Image.file(File(user.get("qrpath") ?? "")),
          if (now.hour < 21 ? now.minute < 56 : false) Text(renderDuration(diff))
        ],
      ),
    );
  }
}