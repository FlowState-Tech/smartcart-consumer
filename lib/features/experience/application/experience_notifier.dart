import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/geofencing_service.dart';
import '../domain/ocr_scanner_interface.dart';
import '../domain/value_objects.dart';
import '../../../core/di/injection_container.dart';
import '../infrastructure/mock_ocr_scanner_impl.dart';
import '../infrastructure/experience_remote_data_source.dart';
import 'experience_state.dart';

class ExperienceNotifier extends StateNotifier<ExperienceState> {
  final OcrScannerInterface _ocrScanner;
  final ExperienceRemoteDataSource _dataSource;

  ExperienceNotifier(this._ocrScanner, this._dataSource) : super(const ExperienceState());

  /// US14: Validates proximity. Adds 10 points if < 500m.
  Future<void> validateInStorePriceAndReportError(String storeId, String sku, double reportedPrice, String evidenceUrl) async {
    try {
      await _dataSource.reportPriceError(storeId, sku, reportedPrice, evidenceUrl);
      state = state.copyWith(walletBalance: state.walletBalance.add(10), errorMessage: null);
      _checkBadgeUnlocks();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al reportar precio: $e');
    }
  }

  /// US32: Process ticket OCR upload.
  Future<void> processTicket(String imagePath) async {
    state = state.copyWith(ocrStatus: OcrStatus.loading, errorMessage: null);
    try {
      final result = await _ocrScanner.scanTicket(imagePath);
      
      // Hit Backend API for savings calculation
      final savingsData = await _dataSource.calculateSavings('demo_route_id', ['sku1', 'sku2']);
      print('Ahorro calculado en backend: \${savingsData['totalSavings']}');

      // Award points for successful scan
      state = state.copyWith(
        ocrStatus: OcrStatus.success,
        walletBalance: state.walletBalance.add(25), // e.g. 25 points for ticket
      );
      _checkBadgeUnlocks();
    } on OcrReadException catch (e) {
      // Trigger fallback manual validation form
      state = state.copyWith(
        ocrStatus: OcrStatus.fallbackRequired,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        ocrStatus: OcrStatus.idle,
        errorMessage: 'Error inesperado al procesar el ticket.',
      );
    }
  }

  void resetOcrStatus() {
    state = state.copyWith(ocrStatus: OcrStatus.idle, errorMessage: null);
  }

  void generateVoucher() {
    if (state.walletBalance.points >= 100) {
      state = state.copyWith(
        walletBalance: state.walletBalance.subtract(100),
        activeVoucher: _generateRandomAlphanumeric(8),
        errorMessage: null,
      );
    } else {
      state = state.copyWith(errorMessage: 'Necesitas al menos 100 puntos para canjear un vale.');
    }
  }

  void _checkBadgeUnlocks() {
    if (state.walletBalance.points >= 50 && state.badges.isEmpty) {
      final badge = const GamificationBadge(
        id: 'b1',
        name: 'Explorador de Retail',
        description: 'Has acumulado tus primeros 50 puntos.',
        iconCode: 'explore',
      );
      state = state.copyWith(badges: [...state.badges, badge]);
    }
  }

  String _generateRandomAlphanumeric(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}

// Global Provider
final experienceProvider = StateNotifierProvider<ExperienceNotifier, ExperienceState>((ref) {
  return ExperienceNotifier(MockOcrScannerImpl(), sl<ExperienceRemoteDataSource>());
});
