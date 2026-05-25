import 'ocr_text_reader.dart';

class UnsupportedOcrTextReader implements OcrTextReader {
  @override
  Future<String?> readTextFromImage(String imagePath) async => null;
}

OcrTextReader createPlatformOcrTextReader() => UnsupportedOcrTextReader();
