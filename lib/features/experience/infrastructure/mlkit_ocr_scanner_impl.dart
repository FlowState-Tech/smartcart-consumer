import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/entities.dart';
import '../domain/ocr_scanner_interface.dart';

class MlKitOcrScannerImpl implements OcrScannerInterface {
  @override
  Future<OcrTicketResult> scanTicket(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await recognizer.processImage(inputImage);
      final text = recognizedText.text;

      if (text.trim().length < 10) {
        throw const OcrReadException('Ticket ilegible. Usa validación manual.');
      }

      final priceMatches = RegExp(r'(\d+[.,]\d{2})').allMatches(text);
      final prices = priceMatches
          .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')))
          .whereType<double>()
          .where((p) => p > 0 && p < 10000)
          .toList();

      if (prices.isEmpty) {
        throw const OcrReadException('No se detectaron precios. Usa validación manual.');
      }

      final variations = prices.take(10).toList().asMap().entries.map((e) {
        return PriceVariation('line_${e.key}', e.value);
      }).toList();

      return OcrTicketResult(
        storeId: 'ocr_store',
        variations: variations,
        scannedAt: DateTime.now(),
      );
    } finally {
      await recognizer.close();
    }
  }
}
