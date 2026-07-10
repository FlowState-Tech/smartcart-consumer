typedef SessionExpiredCallback = void Function();

class SessionEvents {
  static SessionExpiredCallback? onSessionExpired;

  static void notifySessionExpired() {
    onSessionExpired?.call();
  }
}
