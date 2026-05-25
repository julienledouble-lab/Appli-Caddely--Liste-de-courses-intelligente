import 'ocr_text_reader_stub.dart'
    if (dart.library.io) 'ocr_text_reader_mobile.dart';

abstract class OcrTextReader {
  Future<String?> readTextFromImage(String imagePath);
}

OcrTextReader createOcrTextReader() => createPlatformOcrTextReader();
