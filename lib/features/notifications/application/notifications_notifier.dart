import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/providers/session_providers.dart';
import '../infrastructure/notifications_remote_data_source.dart';

class NotificationsState {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool isLoading;
  final bool isLoadingMore;
  final List<Map<String, dynamic>> history;
  final int historyPage;
  final bool hasMoreHistory;

  const NotificationsState({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.history = const [],
    this.historyPage = 0,
    this.hasMoreHistory = true,
  });

  NotificationsState copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? isLoading,
    bool? isLoadingMore,
    List<Map<String, dynamic>>? history,
    int? historyPage,
    bool? hasMoreHistory,
  }) {
    return NotificationsState(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      history: history ?? this.history,
      historyPage: historyPage ?? this.historyPage,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRemoteDataSource _dataSource;
  final int Function() _getUserId;

  NotificationsNotifier(this._dataSource, this._getUserId) : super(const NotificationsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, historyPage: 0);
    try {
      final userId = _getUserId();
      final prefs = await _dataSource.getPreferences(userId);
      final historyRes = await _dataSource.getHistory(userId, page: 0, size: 20);
      final items = _extractHistoryItems(historyRes);
      state = state.copyWith(
        isLoading: false,
        pushEnabled: prefs['pushEnabled'] as bool? ?? prefs['enablePush'] as bool? ?? true,
        emailEnabled: prefs['emailEnabled'] as bool? ?? prefs['enableEmail'] as bool? ?? true,
        history: items,
        historyPage: 0,
        hasMoreHistory: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMoreHistory() async {
    if (state.isLoadingMore || !state.hasMoreHistory) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final userId = _getUserId();
      final nextPage = state.historyPage + 1;
      final historyRes = await _dataSource.getHistory(userId, page: nextPage, size: 20);
      final items = _extractHistoryItems(historyRes);
      state = state.copyWith(
        isLoadingMore: false,
        history: [...state.history, ...items],
        historyPage: nextPage,
        hasMoreHistory: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  List<Map<String, dynamic>> _extractHistoryItems(Map<String, dynamic> historyRes) {
    return (historyRes['content'] as List<dynamic>? ?? historyRes['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<void> setPushEnabled(bool value) async {
    state = state.copyWith(pushEnabled: value);
    await _save();
  }

  Future<void> setEmailEnabled(bool value) async {
    state = state.copyWith(emailEnabled: value);
    await _save();
  }

  Future<void> _save() async {
    try {
      await _dataSource.updatePreferences({
        'userId': _getUserId(),
        'pushEnabled': state.pushEnabled,
        'emailEnabled': state.emailEnabled,
        'enablePush': state.pushEnabled,
        'enableEmail': state.emailEnabled,
      });
    } catch (_) {}
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(
    sl<NotificationsRemoteDataSource>(),
    () => ref.read(currentBuyerIdProvider),
  );
});
