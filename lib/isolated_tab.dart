import 'dart:developer';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_isolate/data_uploader.dart';
import 'package:hive_flutter/adapters.dart';

import 'hive/initialize_hive.dart';

const _kUploadingIndex = "uploading_index";
const _kUploadingTarget = "uploading_target";
const _kInnerUploadingIndex = "inner_uploading_index";
const _kInnerUploadingRef = "inner_uploading_reference";
const _kInnerUploadingError = "inner_uploading_error";

class IsolatedAdminPage extends StatefulWidget {
  final int index;

  const IsolatedAdminPage({
    super.key,
    required this.index,
  });

  @override
  State<IsolatedAdminPage> createState() => _IsolatedAdminPageState();
}

class _IsolatedAdminPageState extends State<IsolatedAdminPage>
    with AutomaticKeepAliveClientMixin {
  late final etStart = TextEditingController(
    text: GetHive.ii("$_kUploadingIndex-${widget.index}", 0).toString(),
  );
  late final etEnd = TextEditingController(
    text: GetHive.ii("$_kUploadingTarget-${widget.index}", 0).toString(),
  );
  late final etInnerStart = TextEditingController(
    text: GetHive.ii("$_kInnerUploadingIndex-${widget.index}", 0).toString(),
  );

  Isolate? _isolate;
  ReceivePort? _receivePort;
  bool isUploading = false;
  bool isStop = false;

  void _completedIndex(int index) {
    // etStart.text = "${index + 1}";
    SaveHive.ii("$_kUploadingIndex-${widget.index}", index);
  }

  void _completed() {
    setState(() {
      isUploading = false;
      isStop = true;
    });
  }

  void _processing(int index, int total, String path) {
    // etInnerStart.text = "${index + 1}";
    final reference = "Index $index of ${total - 1} $path";
    SaveHive.ss("$_kInnerUploadingRef-${widget.index}", reference);
    SaveHive.ii("$_kInnerUploadingIndex-${widget.index}", index);
  }

  void _error(int index, String error) {
    final stack = "${GetHive.ss("$_kInnerUploadingError-${widget.index}", "")}\n$error";
    SaveHive.ss("$_kInnerUploadingError-${widget.index}", stack);
  }

  void _run() async {
    if (isUploading) return;
    setState(() {
      isUploading = true;
      isStop = false;
    });
    final start = int.tryParse(etStart.text);
    final end = int.tryParse(etEnd.text);
    final innerIndex = int.tryParse(etInnerStart.text) ?? 0;
    if (start == null || end == null) return;
    SaveHive.ii("$_kUploadingTarget-${widget.index}", end);
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(DataUploader.isolation, {
      "start": start,
      "end": end,
      "itemIndex": innerIndex,
      "port": _receivePort?.sendPort,
    });

    _receivePort?.listen((message) {
      log("STATUS: $message");
      switch (message["status"]) {
        case "completed":
          _completed();
          break;
        case "completed_index":
          _completedIndex(message["index"]);
          break;
        case "processing":
          _processing(message["index"], message["total"], message["path"]);
          break;
        case "error":
          _error(message["index"], message["error"]);
          break;
      }
    });
  }

  void _stop() {
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort = null;
    _isolate = null;
    setState(() {
      isStop = true;
      isUploading = false;
    });
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: const OutlineInputBorder(),
      floatingLabelAlignment: FloatingLabelAlignment.start,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      children: [
        TextField(
          keyboardType: TextInputType.number,
          controller: etStart,
          decoration: _decoration("Start"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: etEnd,
          keyboardType: TextInputType.number,
          decoration: _decoration("End"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: etInnerStart,
          keyboardType: TextInputType.number,
          decoration: _decoration("Inner index"),
        ),
        const SizedBox(height: 16),
        Center(
          child: ValueListenableBuilder(
            valueListenable: SaveHive.ve().listenable(
              keys: ["$_kInnerUploadingRef-${widget.index}"],
            ),
            builder: (context, value, child) {
              return Text(
                  GetHive.ss("$_kInnerUploadingRef-${widget.index}", ""));
            },
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _run,
          child: Text(isUploading ? "UPLOADING..." : "START"),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _stop,
          child: const Text("STOP"),
        ),
        const SizedBox(height: 16),
        Center(
          child: ValueListenableBuilder(
            valueListenable: SaveHive.ve().listenable(
              keys: ["$_kInnerUploadingError-${widget.index}"],
            ),
            builder: (context, value, child) {
              return Text(
                GetHive.ss("$_kInnerUploadingError-${widget.index}",
                    "No error found!"),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
