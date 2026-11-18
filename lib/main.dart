import 'package:flutter/material.dart';

import 'app.dart';
import 'data/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect the on-device database (Hive -> file on mobile, IndexedDB on web)
  await DatabaseService.instance.init();

  runApp(const AuthentiCallApp());
}
