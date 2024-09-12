import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_isolate/isolate_helper.dart';

class CountTab extends StatefulWidget {
  final int tabIndex;

  const CountTab({super.key, required this.tabIndex});

  @override
  State<CountTab> createState() => _CountTabState();
}

class _CountTabState extends State<CountTab>
    with AutomaticKeepAliveClientMixin {
  String countValue = "Waiting...";
  late ReceivePort _receivePort;
  Isolate? _isolate;

  @override
  bool get wantKeepAlive => true; // This keeps the tab active

  @override
  void initState() {
    super.initState();
    _startIsolate();
  }

  void _startIsolate() async {
    _receivePort = ReceivePort();

    // Spawn the isolate and pass the sendPort of our receivePort
    _isolate = await Isolate.spawn(
      IsolateHelper.execute,
      _receivePort.sendPort,
    );

    // Listen for messages from the isolate
    _receivePort.listen((message) {
      setState(() {
        countValue = "$message";
      });
    });
  }

  @override
  void dispose() {
    _receivePort.close(); // Close the port when the widget is disposed
    _isolate?.kill(priority: Isolate.immediate); // Kill the isolate to free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Ensure super.build is called when using KeepAlive
    return Center(
      child: Text(
        countValue,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
