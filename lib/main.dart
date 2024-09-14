import 'package:flutter/material.dart';

import 'hive/initialize_hive.dart';
import 'uploader/initial.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InitializeHive.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InitialPage(),
    );
  }
}
