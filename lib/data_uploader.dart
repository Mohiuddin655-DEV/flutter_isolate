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
  static void run() async {
    continuous(9998, 9999);
  }

  static Future<void> isolation(Map<String, dynamic> args) async {
    try {
      SendPort port = args["port"];
      DataUploader.continuous(
        args["start"],
        args["end"],
        itemIndex: args["itemIndex"],
        onCompletedIndex: (index) {
          port.send({
            "status": "completed_index",
            "index": index,
          });
        },
        onCompleted: () {
          port.send({
            "status": "completed",
          });
        },
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

  static void continuous(
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
      await push(
        path,
        i == start ? itemIndex : 0,
        upload,
        onProgressing: onProgressing,
        onCanceling: onCanceling,
        onError: onError,
      );
      onCompletedIndex?.call(i);
      if (onCanceling != null && onCanceling()) break;
      log("FILE($path) END");
    }
    onCompleted?.call();
  }

  static Future<void> upload(Food food) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return;
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

  static Future<void> push(
    String path,
    int start,
    Future<void> Function(Food food) callback, {
    OnProgressing? onProgressing,
    OnCanceling? onCanceling,
    OnError? onError,
  }) async {
    try {
      log("FILE($path): LOADING...");
      final raw = await rootBundle.loadString(path);
      log("FILE($path): LOADED");
      final lines = raw.split('\n');
      log("FILE($path): PROCESSING...${lines.length} ITEMS");
      for (int i = start; i < lines.length; i++) {
        log("FILE($path): PROCESSING AT INDEX[$i]");
        final line = lines.elementAtOrNull(i);
        if (line == null) return;
        if (line.trim().isNotEmpty) {
          try {
            Object? raw = jsonDecode(line);
            if (raw is Map<String, dynamic>) {
              final food = Food.from(raw);
              log("FILE($path): UPLOADING AT INDEX[$i]");
              if (onProgressing != null) onProgressing(i, lines.length, path);
              await callback(food);
              if (onCanceling != null && onCanceling()) break;
              log("FILE($path): UPLOADED AT INDEX[$i]");
            } else {
              log("FILE($path): INVALIDATE OBJECT AT INDEX[$i]");
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
      log("FILE($path): PROCESSED");
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
