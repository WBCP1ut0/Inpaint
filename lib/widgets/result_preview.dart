import 'package:flutter/material.dart';
import 'dart:io';

class ResultPreview extends StatelessWidget {
  final File originalImage;
  final File resultImage;
  final VoidCallback onSave;
  final VoidCallback onRetry;

  const ResultPreview({
    super.key,
    required this.originalImage,
    required this.resultImage,
    required this.onSave,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Original'),
                    Image.file(
                      originalImage,
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('Result'),
                    Image.file(
                      resultImage,
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
              ElevatedButton(
                onPressed: onSave,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 