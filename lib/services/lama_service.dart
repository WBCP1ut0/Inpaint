import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'model_downloader.dart';

class LamaService {
  static Interpreter? _interpreter;
  static const int INPUT_SIZE = 512; // LaMa model input size

  static Future<void> initializeModel() async {
    if (_interpreter != null) return;

    await ModelDownloader.downloadModel();
    final modelPath = await ModelDownloader.getModelPath();

    _interpreter = await Interpreter.fromFile(modelPath);
  }

  static Future<File> inpaintImage(File inputImage, File maskImage) async {
    if (_interpreter == null) {
      throw Exception('Model not initialized');
    }

    // Load and preprocess images
    final inputTensor = await _preprocessImage(inputImage, maskImage);
    
    // Prepare output tensor
    final outputShape = [1, INPUT_SIZE, INPUT_SIZE, 3];
    final outputBuffer = List.filled(
      outputShape.reduce((a, b) => a * b),
      0.0,
    );

    // Run inference
    _interpreter!.run(inputTensor, outputBuffer);

    // Post-process the result
    final outputImage = await _postprocessImage(outputBuffer);
    
    // Save the result
    final outputPath = inputImage.path.replaceAll('.jpg', '_inpainted.jpg');
    await File(outputPath).writeAsBytes(outputImage);
    
    return File(outputPath);
  }

  static Future<List<List<List<List<double>>>>> _preprocessImage(
    File inputImage,
    File maskImage,
  ) async {
    // Load images
    final input = img.decodeImage(await inputImage.readAsBytes())!;
    final mask = img.decodeImage(await maskImage.readAsBytes())!;

    // Resize images to model input size
    final resizedInput = img.copyResize(input, width: INPUT_SIZE, height: INPUT_SIZE);
    final resizedMask = img.copyResize(mask, width: INPUT_SIZE, height: INPUT_SIZE);

    // Convert to tensor format and normalize
    var tensorData = List.generate(
      1,
      (_) => List.generate(
        INPUT_SIZE,
        (_) => List.generate(
          INPUT_SIZE,
          (_) => List.filled(4, 0.0), // 3 channels for RGB + 1 for mask
        ),
      ),
    );

    for (var y = 0; y < INPUT_SIZE; y++) {
      for (var x = 0; x < INPUT_SIZE; x++) {
        final pixel = resizedInput.getPixel(x, y);
        final maskPixel = resizedMask.getPixel(x, y);
        
        tensorData[0][y][x][0] = (pixel.r / 255.0) * 2 - 1; // Normalize to [-1, 1]
        tensorData[0][y][x][1] = (pixel.g / 255.0) * 2 - 1;
        tensorData[0][y][x][2] = (pixel.b / 255.0) * 2 - 1;
        tensorData[0][y][x][3] = maskPixel.r / 255.0; // Mask value
      }
    }

    return tensorData;
  }

  static Future<Uint8List> _postprocessImage(List<dynamic> outputBuffer) async {
    // Convert the output buffer to an image
    final output = img.Image(INPUT_SIZE, INPUT_SIZE);
    
    var idx = 0;
    for (var y = 0; y < INPUT_SIZE; y++) {
      for (var x = 0; x < INPUT_SIZE; x++) {
        // Denormalize values from [-1, 1] to [0, 255]
        final r = ((outputBuffer[idx] + 1) / 2 * 255).round().clamp(0, 255);
        final g = ((outputBuffer[idx + 1] + 1) / 2 * 255).round().clamp(0, 255);
        final b = ((outputBuffer[idx + 2] + 1) / 2 * 255).round().clamp(0, 255);
        
        output.setPixelRgb(x, y, r, g, b);
        idx += 3;
      }
    }

    return Uint8List.fromList(img.encodeJpg(output));
  }
} 