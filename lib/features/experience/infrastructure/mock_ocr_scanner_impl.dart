import 'dart:math';
import '../domain/entities.dart';
import '../domain/ocr_scanner_interface.dart';

class MockOcrScannerImpl implements OcrScannerInterface {
  final Random _random = Random();

  @override
  Future<OcrTicketResult> scanTicket(String imagePath) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate 30% failure rate due to wrinkled/unreadable tickets (US32 fallback requirement)
    if (_random.nextDouble() < 0.3) {
      throw const OcrReadException('Ticket is too wrinkled or image is too noisy. Manual validation required.');
    }

    // Success simulation
    return OcrTicketResult(
      storeId: 'store_123',
      variations: const [
        PriceVariation('prod_01', 4.50),
        PriceVariation('prod_02', 2.20),
      ],
      scannedAt: DateTime.now(),
    );
  }
}
