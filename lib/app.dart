import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/page/home.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CírculoDiario',
      theme: AppTheme.light(),
      home: const SafeArea(top: false, bottom: true, child: MyHomePage()),
    );
  }
}
