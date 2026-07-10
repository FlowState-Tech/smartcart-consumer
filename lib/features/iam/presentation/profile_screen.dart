import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';
import 'delete_account_screen.dart';
import 'favorites_screen.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/theme/smartcart_theme.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../experience/application/experience_notifier.dart';
import '../../experience/presentation/rewards_wallet_dashboard.dart';
import '../../notifications/application/notifications_notifier.dart';
import '../../planning/infrastructure/preferences_remote_data_source.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocationPref());
  }

  Future<void> _loadLocationPref() async {
    try {
      final buyerId = ref.read(currentBuyerIdProvider);
      final prefs = await sl<PreferencesRemoteDataSource>().getPreferences(buyerId);
      if (mounted) {
        setState(() {
          _locationEnabled = prefs['homeLatitude'] != null && prefs['homeLongitude'] != null;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleLocation(bool value) async {
    setState(() => _locationEnabled = value);
    if (!value) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa permisos de ubicación en ajustes del sistema')),
        );
        setState(() => _locationEnabled = false);
      }
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      final buyerId = ref.read(currentBuyerIdProvider);
      await sl<PreferencesRemoteDataSource>().updatePreferences(buyerId, {
        'homeLatitude': pos.latitude,
        'homeLongitude': pos.longitude,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación de residencia actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showNotificationHistory() {
    final notifState = ref.read(notificationsProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Historial de notificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (notifState.history.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('Sin notificaciones recientes'))
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...notifState.history.map((n) => ListTile(
                          title: Text(n['title']?.toString() ?? n['message']?.toString() ?? 'Notificación'),
                          subtitle: Text(n['createdAt']?.toString() ?? ''),
                        )),
                    if (notifState.hasMoreHistory)
                      TextButton(
                        onPressed: notifState.isLoadingMore
                            ? null
                            : () => ref.read(notificationsProvider.notifier).loadMoreHistory(),
                        child: notifState.isLoadingMore
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Cargar más'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final expState = ref.watch(experienceProvider);
    final notifState = ref.watch(notificationsProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    ref.listen(authProvider, (prev, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    String email = 'usuario@email.com';
    String name = 'Usuario';
    if (authState is AuthAuthenticated) {
      email = authState.user.email.value;
      name = authState.user.displayName;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: 50,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(60)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 60.0),
                    child: Column(
                      children: [
                        Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        const SizedBox(height: 8),
                        Text(email, style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(context, '${expState.walletBalance.points}', 'Puntos', SmartCartTheme.primaryColor),
                            _buildStat(context, '${expState.purchasesCount}', 'Compras', Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                            _buildStat(context, 'S/ ${expState.totalSavings.toStringAsFixed(0)}', 'Ahorrado', Colors.tealAccent.shade400),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildOption(context, icon: Icons.star, iconColor: Colors.amber, title: 'Favoritas', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                    }),
                    const SizedBox(height: 12),
                    _buildOption(context, icon: Icons.wallet, iconColor: SmartCartTheme.primaryColor, title: 'Recompensas', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RewardsWalletDashboard()));
                    }),
                    const SizedBox(height: 12),
                    _buildToggleOption(
                      context,
                      icon: Icons.notifications,
                      iconColor: Colors.orange,
                      title: notifState.isLoading ? 'Notificaciones...' : 'Notificaciones push',
                      value: notifState.pushEnabled,
                      onChanged: notifState.isLoading ? null : (v) => ref.read(notificationsProvider.notifier).setPushEnabled(v),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleOption(
                      context,
                      icon: Icons.email_outlined,
                      iconColor: Colors.blue,
                      title: 'Notificaciones email',
                      value: notifState.emailEnabled,
                      onChanged: notifState.isLoading ? null : (v) => ref.read(notificationsProvider.notifier).setEmailEnabled(v),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleOption(context, icon: Icons.nightlight_round, iconColor: Colors.orangeAccent, title: 'Modo oscuro', value: isDark, onChanged: (v) {
                      ref.read(themeProvider.notifier).toggleTheme(v);
                    }),
                    const SizedBox(height: 12),
                    _buildToggleOption(context, icon: Icons.location_on, iconColor: Colors.pinkAccent, title: 'Ubicación', value: _locationEnabled, onChanged: _toggleLocation),
                    const SizedBox(height: 12),
                    _buildOption(context, icon: Icons.bar_chart, iconColor: Colors.blueAccent, title: 'Historial', onTap: _showNotificationHistory),
                    const SizedBox(height: 12),
                    _buildOption(context, icon: Icons.emoji_events, iconColor: Colors.brown, title: 'Logros (${expState.badges.length})', onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Logros'),
                          content: expState.badges.isEmpty
                              ? const Text('Aún no has desbloqueado logros')
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: expState.badges.map((b) => ListTile(title: Text(b.name), subtitle: Text(b.description))).toList(),
                                ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    _buildOption(context, icon: Icons.logout, iconColor: Colors.grey, title: 'Cerrar Sesión', onTap: () {
                      ref.read(authProvider.notifier).logout();
                    }),
                    const SizedBox(height: 12),
                    _buildOption(context, icon: Icons.delete_forever, iconColor: Colors.red, title: 'Baja de Servicio', isDestructive: true, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeleteAccountScreen()));
                    }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
      ],
    );
  }

  Widget _buildOption(BuildContext context, {required IconData icon, required Color iconColor, required String title, required VoidCallback onTap, bool isDestructive = false}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant)),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: iconColor),
          title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildToggleOption(BuildContext context, {required IconData icon, required Color iconColor, required String title, required bool value, required ValueChanged<bool>? onChanged}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant)),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: SwitchListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          secondary: Icon(icon, color: iconColor),
          title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16)),
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: SmartCartTheme.primaryColor,
        ),
      ),
    );
  }
}
