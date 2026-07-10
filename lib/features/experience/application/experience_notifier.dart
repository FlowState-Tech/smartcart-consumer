import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/geofencing_service.dart';
import '../domain/ocr_scanner_interface.dart';
import '../domain/value_objects.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/services/wallet_storage.dart';
import '../infrastructure/experience_remote_data_source.dart';
import 'experience_state.dart';

typedef BuyerIdResolver = String Function();

class ExperienceNotifier extends StateNotifier<ExperienceState> {
  final OcrScannerInterface _ocrScanner;
  final ExperienceRemoteDataSource _dataSource;
  final WalletStorage _walletStorage;
  final BuyerIdResolver _getBuyerId;
  int _reviewsPage = 0;
  static const _reviewsPageSize = 10;

  ExperienceNotifier(
    this._ocrScanner,
    this._dataSource,
    this._walletStorage, {
    BuyerIdResolver? getBuyerId,
  })  : _getBuyerId = getBuyerId ?? (() => '1'),
        super(const ExperienceState()) {
    _loadPersistedWallet();
  }

  Future<void> _loadPersistedWallet() async {
    final data = await _walletStorage.load();
    if (data.isEmpty) return;

    final badgesRaw = data['badges'] as List<dynamic>? ?? [];
    final badges = badgesRaw
        .map((b) => GamificationBadge(
              id: b['id'] as String,
              name: b['name'] as String,
              description: b['description'] as String,
              iconCode: b['iconCode'] as String,
            ))
        .toList();

    state = state.copyWith(
      walletBalance: WalletBalance((data['points'] as num?)?.toInt() ?? 0),
      badges: badges,
      activeVoucher: data['activeVoucher'] as String?,
      validationsCount: (data['validationsCount'] as num?)?.toInt() ?? 0,
      purchasesCount: (data['purchasesCount'] as num?)?.toInt() ?? 0,
      totalSavings: (data['totalSavings'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<void> _persistWallet({double? lastSavings}) async {
    await _walletStorage.save(
      points: state.walletBalance.points,
      badges: state.badges,
      activeVoucher: state.activeVoucher,
      lastSavings: lastSavings,
      validationsCount: state.validationsCount,
      purchasesCount: state.purchasesCount,
      totalSavings: state.totalSavings,
    );
  }

  Future<void> _awardPoints(int points, {bool countValidation = true}) async {
    if (points <= 0) return;
    state = state.copyWith(
      walletBalance: state.walletBalance.add(points),
      validationsCount: countValidation ? state.validationsCount + 1 : state.validationsCount,
    );
    _checkBadgeUnlocks();
    await _persistWallet();
  }

  int _pointsFromResponse(Map<String, dynamic> response, {int fallback = 0}) {
    return (response['pointsAwarded'] as num?)?.toInt() ??
        (response['points'] as num?)?.toInt() ??
        fallback;
  }

  Future<void> _awardFromResponse(Map<String, dynamic> response, {int fallback = 0, bool countValidation = true}) async {
    await _awardPoints(_pointsFromResponse(response, fallback: fallback), countValidation: countValidation);
  }

  void setJourneyContext({
    required String recorridoId,
    required String storeId,
    required String storeName,
    double? storeLat,
    double? storeLng,
  }) {
    state = state.copyWith(
      activeRecorridoId: recorridoId,
      activeStoreId: storeId,
      activeStoreName: storeName,
      storeLat: storeLat,
      storeLng: storeLng,
      clearError: true,
      clearSuccess: true,
    );
    loadStoreReviews(storeId);
    loadSavings(recorridoId);
    loadTrustProfile(storeId);
  }

  Future<void> recordPurchase() async {
    state = state.copyWith(purchasesCount: state.purchasesCount + 1);
    await _persistWallet();
  }

  Future<void> loadSavings(String recorridoId) async {
    try {
      final data = await _dataSource.getSavings(recorridoId);
      state = state.copyWith(savingsData: data);
    } catch (_) {}
  }

  Future<void> loadTrustProfile(String storeId) async {
    try {
      final profile = await _dataSource.getTrustProfile(storeId);
      state = state.copyWith(trustProfile: profile);
    } catch (_) {}
  }

  void selectProductForValidation({
    required String sku,
    required String name,
    required double digitalPrice,
  }) {
    state = state.copyWith(
      selectedProductSku: sku,
      selectedProductName: name,
      selectedDigitalPrice: digitalPrice,
      clearError: true,
    );
  }

  Future<bool> _ensureNearStore() async {
    final lat = state.storeLat;
    final lng = state.storeLng;
    if (lat == null || lng == null) return true;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition();
    final isNear = GeofencingService.isWithinStoreRadius(
      position.latitude,
      position.longitude,
      lat,
      lng,
    );

    if (!isNear) {
      state = state.copyWith(
        errorMessage: 'Debes estar a menos de 500 m de la tienda para validar.',
      );
    }
    return isNear;
  }

  Future<void> confirmProductPrice() async {
    if (!state.hasJourneyContext || state.selectedProductSku == null) {
      state = state.copyWith(errorMessage: 'Selecciona un producto y completa un recorrido primero.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      if (!await _ensureNearStore()) {
        state = state.copyWith(isSubmitting: false);
        return;
      }

      final savingsRes = await _dataSource.calculateSavings(
        recorridoId: state.activeRecorridoId!,
        buyerId: _getBuyerId(),
        precioReferencia: state.selectedDigitalPrice ?? 0,
        precioPagado: state.selectedDigitalPrice ?? 0,
        moneda: 'PEN',
      );

      state = state.copyWith(isSubmitting: false, successMessage: 'Precio confirmado');
      await _awardFromResponse(savingsRes, fallback: 10);
      if (state.activeRecorridoId != null) await loadSavings(state.activeRecorridoId!);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> reportProductPriceError(double physicalPrice) async {
    if (!state.hasJourneyContext || state.selectedProductSku == null) {
      state = state.copyWith(errorMessage: 'Selecciona un producto para reportar.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      if (!await _ensureNearStore()) {
        state = state.copyWith(isSubmitting: false);
        return;
      }

      final reportRes = await _dataSource.reportPriceError(
        storeId: state.activeStoreId!,
        buyerId: _getBuyerId(),
        recorridoId: state.activeRecorridoId!,
        productoId: state.selectedProductSku!,
        precioDigital: state.selectedDigitalPrice ?? 0,
        precioFisico: physicalPrice,
        moneda: 'PEN',
      );

      state = state.copyWith(isSubmitting: false, successMessage: 'Reporte enviado');
      await _awardFromResponse(reportRes, fallback: 10);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> reportOfferIssue({
    required String productoId,
    required double precioDigital,
    required double precioFisico,
    String? evidenceImagePath,
  }) async {
    if (!state.hasJourneyContext) {
      state = state.copyWith(errorMessage: 'Completa un recorrido antes de reportar.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final reportRes = await _dataSource.reportPriceError(
        storeId: state.activeStoreId!,
        buyerId: _getBuyerId(),
        recorridoId: state.activeRecorridoId!,
        productoId: productoId,
        precioDigital: precioDigital,
        precioFisico: precioFisico,
        moneda: 'PEN',
      );
      state = state.copyWith(
        isSubmitting: false,
        successMessage: evidenceImagePath != null ? 'Reporte con evidencia enviado' : 'Oferta reportada',
      );
      await _awardFromResponse(reportRes, fallback: 15);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> processTicket(String imagePath, {double? referenceTotal, double? paidTotal}) async {
    state = state.copyWith(ocrStatus: OcrStatus.loading, clearError: true);
    try {
      final ocrResult = await _ocrScanner.scanTicket(imagePath);
      final detectedPrices = ocrResult.variations.map((v) => v.newPrice).toList();
      final refTotal = referenceTotal ?? (detectedPrices.isNotEmpty ? detectedPrices.reduce(max) : 50.0);
      final paid = paidTotal ?? refTotal;

      if (state.hasJourneyContext) {
        await _dataSource.calculateSavings(
          recorridoId: state.activeRecorridoId!,
          buyerId: _getBuyerId(),
          precioReferencia: refTotal,
          precioPagado: paid,
          moneda: 'PEN',
        );
        await loadSavings(state.activeRecorridoId!);
        final amount = (state.savingsData?['montoAhorro'] as num?)?.toDouble() ??
            (state.savingsData?['savingsAmount'] as num?)?.toDouble() ??
            (refTotal - paid).abs();
        if (amount > 0) {
          state = state.copyWith(totalSavings: state.totalSavings + amount);
          await _persistWallet(lastSavings: amount);
        }
      }

      state = state.copyWith(ocrStatus: OcrStatus.success, successMessage: 'Ticket validado. +25 pts');
      await _awardPoints(25);
    } on OcrReadException catch (e) {
      state = state.copyWith(
        ocrStatus: OcrStatus.fallbackRequired,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        ocrStatus: OcrStatus.idle,
        errorMessage: 'Error al procesar el ticket: $e',
      );
    }
  }

  Future<void> submitManualTicketValidation(double paidTotal, double referenceTotal) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      if (state.hasJourneyContext) {
        await _dataSource.calculateSavings(
          recorridoId: state.activeRecorridoId!,
          buyerId: _getBuyerId(),
          precioReferencia: referenceTotal,
          precioPagado: paidTotal,
          moneda: 'PEN',
        );
        await loadSavings(state.activeRecorridoId!);
      }
      state = state.copyWith(isSubmitting: false, ocrStatus: OcrStatus.success, successMessage: 'Validación manual enviada. +25 pts');
      await _awardPoints(25);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> submitRating(int stars) async {
    if (!state.hasJourneyContext) {
      state = state.copyWith(errorMessage: 'Finaliza un recorrido para calificar la tienda.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final ratingRes = await _dataSource.rateStore(
        storeId: state.activeStoreId!,
        buyerId: _getBuyerId(),
        recorridoId: state.activeRecorridoId!,
        puntuacion: stars,
      );
      state = state.copyWith(isSubmitting: false, lastRating: stars, successMessage: 'Calificación enviada');
      await _awardFromResponse(ratingRes, fallback: 5, countValidation: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> submitReview(String comentario) async {
    if (!state.hasJourneyContext) {
      state = state.copyWith(errorMessage: 'Finaliza un recorrido para dejar un comentario.');
      return;
    }
    if (comentario.trim().length < 10) {
      state = state.copyWith(errorMessage: 'El comentario debe tener al menos 10 caracteres.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final reviewRes = await _dataSource.postReview(
        storeId: state.activeStoreId!,
        buyerId: _getBuyerId(),
        recorridoId: state.activeRecorridoId!,
        comentario: comentario.trim(),
      );
      await loadStoreReviews(state.activeStoreId!);
      state = state.copyWith(isSubmitting: false, successMessage: 'Reseña publicada');
      await _awardFromResponse(reviewRes, fallback: 10, countValidation: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> loadStoreReviews(String storeId, {bool refresh = true}) async {
    if (refresh) _reviewsPage = 0;
    state = state.copyWith(isLoadingReviews: true);
    try {
      final raw = await _dataSource.getPublishedReviews(storeId, page: _reviewsPage, size: _reviewsPageSize);
      final reviews = raw.map((r) {
        return StoreReviewItem(
          reviewId: (r['reviewId'] ?? '').toString(),
          comentario: r['comentario'] as String? ?? '',
          buyerId: r['buyerId'] as String?,
          fechaCreacion: r['fechaCreacion'] != null
              ? DateTime.tryParse(r['fechaCreacion'].toString())
              : null,
        );
      }).toList();
      state = state.copyWith(
        storeReviews: refresh ? reviews : [...state.storeReviews, ...reviews],
        hasMoreReviews: reviews.length >= _reviewsPageSize,
        isLoadingReviews: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingReviews: false);
    }
  }

  Future<void> loadMoreStoreReviews(String storeId) async {
    if (!state.hasMoreReviews || state.isLoadingReviews) return;
    _reviewsPage++;
    await loadStoreReviews(storeId, refresh: false);
  }

  void resetOcrStatus() {
    state = state.copyWith(ocrStatus: OcrStatus.idle, clearError: true);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<void> generateVoucher() async {
    if (state.walletBalance.points >= 100) {
      state = state.copyWith(
        walletBalance: state.walletBalance.subtract(100),
        activeVoucher: _generateRandomAlphanumeric(8),
        clearError: true,
      );
      await _persistWallet();
    } else {
      state = state.copyWith(errorMessage: 'Necesitas al menos 100 puntos para canjear un vale.');
    }
  }

  Future<void> clearLocalData() async {
    await _walletStorage.clear();
    state = const ExperienceState();
  }

  void _checkBadgeUnlocks() {
    if (state.walletBalance.points >= 50 && !state.badges.any((b) => b.id == 'b1')) {
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

final experienceProvider = StateNotifierProvider<ExperienceNotifier, ExperienceState>((ref) {
  return ExperienceNotifier(
    sl<OcrScannerInterface>(),
    sl<ExperienceRemoteDataSource>(),
    sl<WalletStorage>(),
    getBuyerId: () => ref.read(currentBuyerIdStringProvider),
  );
});
