import 'package:flutter/material.dart';
import 'package:flutter_isolate/uploader/data_uploader.dart';
import 'package:hive_flutter/adapters.dart';

import '../hive/initialize_hive.dart';

const _kUploadingIndex = "uploading_index";
const _kUploadingTarget = "uploading_target";
const _kInnerUploadingIndex = "inner_uploading_index";
const _kInnerUploadingRef = "inner_uploading_reference";
const _kInnerUploadingError = "inner_uploading_error";

class IsolatedAdminPage extends StatefulWidget {
  final int isolate;

  const IsolatedAdminPage({
    super.key,
    required this.isolate,
  });

  @override
  State<IsolatedAdminPage> createState() => _IsolatedAdminPageState();
}

class _IsolatedAdminPageState extends State<IsolatedAdminPage>
    with AutomaticKeepAliveClientMixin {
  late final etStart = TextEditingController(
    text: GetHive.ii("$_kUploadingIndex-${widget.isolate}", 0).toString(),
  );
  late final etEnd = TextEditingController(
    text: GetHive.ii("$_kUploadingTarget-${widget.isolate}", 0).toString(),
  );
  late final etInnerStart = TextEditingController(
    text: GetHive.ii("$_kInnerUploadingIndex-${widget.isolate}", 0).toString(),
  );

  bool isUploading = false;

  void _run() {
    if (isUploading) return;
    setState(() {
      isUploading = true;
    });
    final start = int.tryParse(etStart.text);
    final end = int.tryParse(etEnd.text);
    final innerIndex = int.tryParse(etInnerStart.text) ?? 0;
    if (start == null || end == null) return;
    SaveHive.ii("$_kUploadingTarget-${widget.isolate}", end);
    DataUploader.isolate(
      start,
      end,
      itemIndex: innerIndex,
      onCompletedIndex: (index) {
        // etStart.text = "${index + 1}";
        SaveHive.ii("$_kUploadingIndex-${widget.isolate}", index);
      },
      onCompleted: () {
        setState(() {
          isUploading = false;
        });
      },
      onProgressing: (index, total, path) {
        // etInnerStart.text = "${index + 1}";
        final reference = "Index $index of ${total - 1} $path";
        SaveHive.ss("$_kInnerUploadingRef-${widget.isolate}", reference);
        SaveHive.ii("$_kInnerUploadingIndex-${widget.isolate}", index);
      },
      onError: (index, error) {
        final stack =
            "${GetHive.ss("$_kInnerUploadingError-${widget.isolate}", "")}\n$error";
        SaveHive.ss("$_kInnerUploadingError-${widget.isolate}", stack);
        setState(() {
          isUploading = false;
        });
      },
    );
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
    return Scaffold(
      body: ListView(
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
                keys: ["$_kInnerUploadingRef-${widget.isolate}"],
              ),
              builder: (context, value, child) {
                return Text(
                    GetHive.ss("$_kInnerUploadingRef-${widget.isolate}", ""));
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _run,
            child: Text(isUploading ? "UPLOADING..." : "START"),
          ),
          const SizedBox(height: 16),
          Center(
            child: ValueListenableBuilder(
              valueListenable: SaveHive.ve().listenable(
                keys: ["$_kInnerUploadingError-${widget.isolate}"],
              ),
              builder: (context, value, child) {
                return Text(
                  GetHive.ss("$_kInnerUploadingError-${widget.isolate}",
                      "No error found!"),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
