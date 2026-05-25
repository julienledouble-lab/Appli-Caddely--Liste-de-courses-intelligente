import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_text_reader.dart';

class MlKitOcrTextReader implements OcrTextReader {
  @override
  Future<String?> readTextFromImage(String imagePath) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return null;
    }

    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Fichier image introuvable : $imagePath');
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = InputImage.fromFile(file);
      final result = await recognizer.processImage(image);
      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } finally {
      await recognizer.close();
    }
  }
}

OcrTextReader createPlatformOcrTextReader() => MlKitOcrTextReader();
