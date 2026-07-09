import 'entities.dart';

class OcrReadException implements Exception {
  final String message;
  const OcrReadException(this.message);
  
  @override
  String toString() => 'OcrReadException: $message';
}

abstract class OcrScannerInterface {
  /// Simulates reading a physical ticket from an image path.
  /// Throws [OcrReadException] if the ticket is wrinkled or unreadable.
  Future<OcrTicketResult> scanTicket(String imagePath);
}
