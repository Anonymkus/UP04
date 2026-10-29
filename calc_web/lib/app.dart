import 'package:flutter/material.dart';

import 'logic/settings.dart';
import 'router.dart';

class CalcApp extends StatelessWidget {
  const CalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Settings.instance.darkMode,
      builder: (context, dark, _) => MaterialApp.router(
        title: 'Калькулятор и конвертер',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.light),
        darkTheme: ThemeData(brightness: Brightness.dark),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: appRouter,
      ),
    );
  }
}
