import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrScannerService {
  static Future<String?> scanImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('Error scanning text: $e');
      return null;
    } finally {
      textRecognizer.close();
    }
  }

  static double? extractAmount(String text) {
    // Basic regex to find amounts, e.g. 150.00
    final RegExp regExp = RegExp(r'(\d+\.\d{2})');
    final Iterable<Match> matches = regExp.allMatches(text);
    if (matches.isNotEmpty) {
      // Return the largest amount found, which is often the total
      double maxAmount = 0;
      for (final match in matches) {
        final amount = double.tryParse(match.group(0) ?? '0') ?? 0;
        if (amount > maxAmount) maxAmount = amount;
      }
      return maxAmount > 0 ? maxAmount : null;
    }
    return null;
  }
}
