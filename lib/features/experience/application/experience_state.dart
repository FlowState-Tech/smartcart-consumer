import 'package:equatable/equatable.dart';
import '../domain/value_objects.dart';

enum OcrStatus { idle, loading, success, fallbackRequired }

class StoreReviewItem extends Equatable {
  final String reviewId;
  final String comentario;
  final String? buyerId;
  final DateTime? fechaCreacion;

  const StoreReviewItem({
    required this.reviewId,
    required this.comentario,
    this.buyerId,
    this.fechaCreacion,
  });

  @override
  List<Object?> get props => [reviewId, comentario, buyerId, fechaCreacion];
}

class ExperienceState extends Equatable {
  final WalletBalance walletBalance;
  final List<GamificationBadge> badges;
  final OcrStatus ocrStatus;
  final String? errorMessage;
  final String? successMessage;
  final String? activeVoucher;
  final String? activeRecorridoId;
  final String? activeStoreId;
  final String? activeStoreName;
  final double? storeLat;
  final double? storeLng;
  final String? selectedProductSku;
  final String? selectedProductName;
  final double? selectedDigitalPrice;
  final List<StoreReviewItem> storeReviews;
  final bool isSubmitting;
  final int? lastRating;
  final Map<String, dynamic>? savingsData;
  final Map<String, dynamic>? trustProfile;
  final int validationsCount;
  final int purchasesCount;
  final double totalSavings;
  final bool hasMoreReviews;
  final bool isLoadingReviews;

  const ExperienceState({
    this.walletBalance = const WalletBalance(0),
    this.badges = const [],
    this.ocrStatus = OcrStatus.idle,
    this.errorMessage,
    this.successMessage,
    this.activeVoucher,
    this.activeRecorridoId,
    this.activeStoreId,
    this.activeStoreName,
    this.storeLat,
    this.storeLng,
    this.selectedProductSku,
    this.selectedProductName,
    this.selectedDigitalPrice,
    this.storeReviews = const [],
    this.isSubmitting = false,
    this.lastRating,
    this.savingsData,
    this.trustProfile,
    this.validationsCount = 0,
    this.purchasesCount = 0,
    this.totalSavings = 0,
    this.hasMoreReviews = true,
    this.isLoadingReviews = false,
  });

  bool get hasJourneyContext => activeRecorridoId != null && activeStoreId != null;

  ExperienceState copyWith({
    WalletBalance? walletBalance,
    List<GamificationBadge>? badges,
    OcrStatus? ocrStatus,
    String? errorMessage,
    String? successMessage,
    String? activeVoucher,
    String? activeRecorridoId,
    String? activeStoreId,
    String? activeStoreName,
    double? storeLat,
    double? storeLng,
    String? selectedProductSku,
    String? selectedProductName,
    double? selectedDigitalPrice,
    List<StoreReviewItem>? storeReviews,
    bool? isSubmitting,
    int? lastRating,
    Map<String, dynamic>? savingsData,
    Map<String, dynamic>? trustProfile,
    int? validationsCount,
    int? purchasesCount,
    double? totalSavings,
    bool? hasMoreReviews,
    bool? isLoadingReviews,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearVoucher = false,
  }) {
    return ExperienceState(
      walletBalance: walletBalance ?? this.walletBalance,
      badges: badges ?? this.badges,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      activeVoucher: clearVoucher ? null : (activeVoucher ?? this.activeVoucher),
      activeRecorridoId: activeRecorridoId ?? this.activeRecorridoId,
      activeStoreId: activeStoreId ?? this.activeStoreId,
      activeStoreName: activeStoreName ?? this.activeStoreName,
      storeLat: storeLat ?? this.storeLat,
      storeLng: storeLng ?? this.storeLng,
      selectedProductSku: selectedProductSku ?? this.selectedProductSku,
      selectedProductName: selectedProductName ?? this.selectedProductName,
      selectedDigitalPrice: selectedDigitalPrice ?? this.selectedDigitalPrice,
      storeReviews: storeReviews ?? this.storeReviews,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastRating: lastRating ?? this.lastRating,
      savingsData: savingsData ?? this.savingsData,
      trustProfile: trustProfile ?? this.trustProfile,
      validationsCount: validationsCount ?? this.validationsCount,
      purchasesCount: purchasesCount ?? this.purchasesCount,
      totalSavings: totalSavings ?? this.totalSavings,
      hasMoreReviews: hasMoreReviews ?? this.hasMoreReviews,
      isLoadingReviews: isLoadingReviews ?? this.isLoadingReviews,
    );
  }

  @override
  List<Object?> get props => [
        walletBalance,
        badges,
        ocrStatus,
        errorMessage,
        successMessage,
        activeVoucher,
        activeRecorridoId,
        activeStoreId,
        activeStoreName,
        storeLat,
        storeLng,
        selectedProductSku,
        selectedProductName,
        selectedDigitalPrice,
        storeReviews,
        isSubmitting,
        lastRating,
        savingsData,
        trustProfile,
        validationsCount,
        purchasesCount,
        totalSavings,
        hasMoreReviews,
        isLoadingReviews,
      ];
}
