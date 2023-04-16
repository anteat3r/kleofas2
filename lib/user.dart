import 'package:flutter/material.dart';

class UserPage extends StatefulWidget {
  final DateTime date;
  const UserPage(this.date, {Key? key}): super(key: key);
  @override
  State<UserPage> createState() => _UserPageSate();
}

class _UserPageSate extends State<UserPage> {
  @override
  Widget build (BuildContext context) {
    return const Scaffold();
  }
}
  