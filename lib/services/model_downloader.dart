import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ModelDownloader {
  static const String MODEL_URL = 'YOUR_MODEL_HOSTING_URL/lama_model.tflite';
  static const String MODEL_FILENAME = 'lama_model.tflite';

  static Future<String> getModelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$MODEL_FILENAME';
  }

  static Future<bool> modelExists() async {
    final modelPath = await getModelPath();
    return File(modelPath).exists();
  }

  static Future<void> downloadModel() async {
    if (await modelExists()) return;

    final modelPath = await getModelPath();
    final response = await http.get(Uri.parse(MODEL_URL));
    
    if (response.statusCode == 200) {
      await File(modelPath).writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download model');
    }
  }
} 