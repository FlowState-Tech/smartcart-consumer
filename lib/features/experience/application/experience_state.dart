import 'package:equatable/equatable.dart';
import '../domain/value_objects.dart';
import '../domain/entities.dart';

enum OcrStatus { idle, loading, success, fallbackRequired }

class ExperienceState extends Equatable {
  final WalletBalance walletBalance;
  final List<GamificationBadge> badges;
  final OcrStatus ocrStatus;
  final String? errorMessage;
  final String? activeVoucher;

  const ExperienceState({
    this.walletBalance = const WalletBalance(0),
    this.badges = const [],
    this.ocrStatus = OcrStatus.idle,
    this.errorMessage,
    this.activeVoucher,
  });

  ExperienceState copyWith({
    WalletBalance? walletBalance,
    List<GamificationBadge>? badges,
    OcrStatus? ocrStatus,
    String? errorMessage,
    String? activeVoucher,
  }) {
    return ExperienceState(
      walletBalance: walletBalance ?? this.walletBalance,
      badges: badges ?? this.badges,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      errorMessage: errorMessage, // We want to be able to nullify it
      activeVoucher: activeVoucher ?? this.activeVoucher,
    );
  }

  @override
  List<Object?> get props => [walletBalance, badges, ocrStatus, errorMessage, activeVoucher];
}
