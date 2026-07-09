import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart'; // for authProvider
import '../application/auth_state.dart';
import 'delete_account_screen.dart';
import 'delete_account_screen.dart';
import '../../../core/theme/smartcart_theme.dart';
import '../../../core/theme/theme_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notifications = true;
  bool _location = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    ref.listen(authProvider, (prev, next) {
      if (next is AuthUnauthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });

    String email = 'juan.perez@email.com';
    String name = 'Juan Pérez';
    if (authState is AuthAuthenticated) {
      email = authState.user.email.value;
      name = email.split('@').first;
      if (name.isNotEmpty) {
        name = name[0].toUpperCase() + name.substring(1);
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top decorative curve and profile info
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
                        Text(
                          name,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(height: 32),
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(context, '124', 'Puntos', SmartCartTheme.primaryColor),
                            _buildStat(context, '28', 'Compras', Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                            _buildStat(context, 'S/ 420', 'Ahorrado', Colors.tealAccent.shade400),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // List Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildOption(context, icon: Icons.star, iconColor: Colors.amber, title: 'Favoritas', onTap: () {}),
                    const SizedBox(height: 12),
                    _buildToggleOption(context, icon: Icons.notifications, iconColor: Colors.orange, title: 'Notificaciones', value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
                    const SizedBox(height: 12),
                    _buildToggleOption(context, icon: Icons.nightlight_round, iconColor: Colors.orangeAccent, title: 'Modo oscuro', value: isDark, onChanged: (v) {
                      ref.read(themeProvider.notifier).toggleTheme(v);
                    }),
                    const SizedBox(height: 12),
                    _buildToggleOption(context, icon: Icons.location_on, iconColor: Colors.pinkAccent, title: 'Ubicación', value: _location, onChanged: (v) => setState(() => _location = v)),
                    const SizedBox(height: 12),
                    _buildOption(context, icon: Icons.bar_chart, iconColor: Colors.blueAccent, title: 'Historial', onTap: () {}),
                    const SizedBox(height: 12),
                    _buildOption(context, icon: Icons.emoji_events, iconColor: Colors.brown, title: 'Logros', onTap: () {}),
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
              )
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
      ),
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

  Widget _buildToggleOption(BuildContext context, {required IconData icon, required Color iconColor, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
      ),
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
