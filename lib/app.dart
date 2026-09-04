import 'package:flutter/material.dart';

import 'package:edtech_tiktok/home.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ed Tech',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const SafeArea(top: false, bottom: true, child: MyHomePage()),
    );
  }
}
