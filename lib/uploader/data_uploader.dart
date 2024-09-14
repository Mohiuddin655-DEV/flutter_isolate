import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_andomie/core.dart';

typedef OnProgressing = void Function(int index, int total, String name);
typedef OnError = void Function(int index, String error);
typedef OnCanceling = bool Function();
typedef OnCompletedIndex = void Function(int index);

final Dio dio = Dio();

class DataUploader {
  static Future<void> upload(Food food) async {
    if (food.isValidFood) {
      final source = food.source;
      try {
        final response = await dio.post(
          "https://drcal.up.railway.app/foods/",
          data: source,
        );

        log("STATUS: ${response.statusCode}");
      } catch (error) {
        log("ERROR: $error");
      }
    }
    return;
  }

  static Future<void> _startIsolate({
    required String path,
    required String data,
    required int index,
    required OnProgressing? onProgressing,
    required OnCompletedIndex? onCompletedIndex,
    required OnError? onError,
    required VoidCallback? onCompleted,
  }) async {
    try {
      final receivePort = ReceivePort();
      await Isolate.spawn(_task, {
        "path": path,
        "data": data,
        "index": index,
        "port": receivePort.sendPort,
      });
      receivePort.listen((message) {
        log("STATUS: $message");
        switch (message["status"]) {
          case "completed":
            onCompleted?.call();
            break;
          case "completed_index":
            onCompletedIndex?.call(message["index"]);
            break;
          case "processing":
            onProgressing?.call(
                message["index"], message["total"], message["path"]);
            break;
          case "error":
            onError?.call(message["index"], message["error"]);
            break;
        }
      });
      await receivePort.first;
    } catch (_) {}
  }

  static void isolate(
    int start,
    int end, {
    int itemIndex = 0,
    OnProgressing? onProgressing,
    OnCanceling? onCanceling,
    OnCompletedIndex? onCompletedIndex,
    OnError? onError,
    VoidCallback? onCompleted,
  }) async {
    for (int i = start; i <= end; i++) {
      final path = "assets/collections/$i.txt";
      log("FILE($path) START");
      await _startIsolate(
        data: await rootBundle.loadString(path),
        path: path,
        index: itemIndex,
        onError: onError,
        onCompleted: onCompleted,
        onCompletedIndex: onCompletedIndex,
        onProgressing: onProgressing,
      );
      onCompletedIndex?.call(i);
      if (onCanceling != null && onCanceling()) break;
      log("FILE($path) END");
    }
    onCompleted?.call();
  }

  static Future<void> _task(Map<String, dynamic> args) async {
    try {
      SendPort port = args["port"];
      push(
        path: args["path"],
        data: args["data"],
        index: args["index"],
        callback: upload,
        onProgressing: (index, total, path) {
          port.send({
            "status": "processing",
            "index": index,
            "total": total,
            "path": path,
          });
        },
        onError: (index, error) {
          port.send({
            "status": "error",
            "index": index,
            "error": error,
          });
        },
        onCanceling: () => false,
      );
    } catch (_) {
      log("message: $_");
    }
  }

  static Future<void> push({
    required String path,
    required String data,
    required int index,
    required Future<void> Function(Food food) callback,
    OnProgressing? onProgressing,
    OnCanceling? onCanceling,
    OnError? onError,
  }) async {
    try {
      final lines = data.split('\n');
      for (int i = index; i < lines.length; i++) {
        final line = lines.elementAtOrNull(i);
        if (line == null) return;
        if (line.trim().isNotEmpty) {
          try {
            Object? raw = jsonDecode(line);
            if (raw is Map<String, dynamic>) {
              final food = Food.from(raw);
              if (onProgressing != null) onProgressing(i, lines.length, path);
              await callback(food);
              if (onCanceling != null && onCanceling()) break;
            } else {
              if (onError != null) {
                onError(i, "FILE($path): INVALIDATE OBJECT AT INDEX[$i]");
              }
            }
          } catch (_) {
            log("FILE($path): FAILED AT INDEX[$i]");
            if (onError != null) onError(i, "FILE($path): FAILED AT INDEX[$i]");
          }
        } else {
          log("FILE($path): INVALIDATE LINE AT INDEX[$i]");
          if (onError != null) {
            onError(i, "FILE($path): INVALIDATE LINE AT INDEX[$i]");
          }
        }
      }
    } catch (e) {
      log("FILE($path): FAILED");
      if (onError != null) onError(0, "FILE($path): FAILED");
    }
  }
}

class Food {
  final num? completeness;
  final String? code;
  final String? name;
  final String? brand;
  final Nutriments? nutriments;

  const Food({
    this.code,
    this.completeness,
    this.nutriments,
    this.name,
    this.brand,
  });

  bool get isValidFood {
    final nutriments = this.nutriments;
    if (code.use.isEmpty || nutriments == null || name.use.isEmpty) {
      return false;
    }
    return completeness.use > 0.2
        // &&
        // nutriments.carbohydrates.isValid &&
        // nutriments.fat.isValid &&
        // nutriments.proteins.isValid
        ;
  }

  factory Food.from(Map<String, dynamic> source) {
    String? name = source.findOrNull(key: "product_name");
    String? code =
        source.findOrNull(key: "code") ?? source.findOrNull(key: "id");
    String? brand = source.findOrNull(key: "brands");
    num? completeness = source.findOrNull(key: "completeness");
    return Food(
      code: code,
      completeness: completeness,
      brand: brand ?? '',
      name: name,
      nutriments: source["nutriments"] == null
          ? null
          : Nutriments.from(source["nutriments"]),
    );
  }

  Map<String, dynamic> get source {
    return {
      "code": code,
      "name": name,
      "brand": brand,
      ...(nutriments?.source ?? {}),
    };
  }
}

class Nutriments {
  final num? carbs;
  final num? fats;
  final num? calories;
  final num? proteins;

  const Nutriments({
    this.proteins,
    this.calories,
    this.carbs,
    this.fats,
  });

  factory Nutriments.from(Map<String, dynamic> source) {
    num? proteins100g = source.findOrNull(key: "proteins_100g");
    num? proteinsServing = source.findOrNull(key: "proteins_serving");
    num? calories100g = source.findOrNull(key: "energy-kcal_100g");
    num? caloriesServing = source.findOrNull(key: "energy-kcal_serving");
    num? carbs100g = source.findOrNull(key: "carbohydrates_100g");
    num? carbsServing = source.findOrNull(key: "carbohydrates_serving");
    num? fats100g = source.findOrNull(key: "fat_100g");
    num? fatsServing = source.findOrNull(key: "fat_serving");
    return Nutriments(
      proteins: proteinsServing ?? proteins100g,
      calories: caloriesServing ?? calories100g,
      carbs: carbsServing ?? carbs100g,
      fats: fatsServing ?? fats100g,
    );
  }

  /*
  code: String,
    name: String,
    brand: String,
    photo: String,

    calories: Number,
    carbs: Number,
    fats: Number,
    proteins: Number
  * */
  Map<String, dynamic> get source {
    return {
      "calories": calories,
      "fats": fats,
      "carbs": carbs,
      "proteins": proteins,
    };
  }
}
