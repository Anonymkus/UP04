import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'logic/settings.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.instance.load();
  runApp(const CalcApp());
}
