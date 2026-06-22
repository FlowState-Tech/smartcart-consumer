import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // Para acceder a themeNotifier

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    // Detectamos si estamos en modo oscuro o claro para los colores
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[500];
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header con Avatar mejorado
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Tarjeta de información de usuario
                  Container(
                    margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
                    padding: const EdgeInsets.only(top: 60, bottom: 28, left: 16, right: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Juan Pérez",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "juan.perez@email.com",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Estadísticas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem("124", "Puntos", const Color(0xFF4A89DC), subtitleColor!),
                            _buildStatItem("28", "Compras", textColor, subtitleColor),
                            _buildStatItem("S/ 420", "Ahorrado", const Color(0xFF2ECA9A), subtitleColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Avatar Circle mejor acomodado
                  Positioned(
                    top: 10,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor, 
                          width: 6
                        ),
                      ),
                      child: Icon(Icons.person, size: 50, color: isDark ? Colors.grey[600] : Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Opciones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildOptionItem(
                      icon: Icons.star,
                      iconColor: Colors.amber,
                      title: "Favoritas",
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      cardColor: cardColor,
                      textColor: textColor,
                      borderColor: borderColor,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildOptionItem(
                      icon: Icons.notifications,
                      iconColor: Colors.orangeAccent,
                      title: "Notificaciones",
                      cardColor: cardColor,
                      textColor: textColor,
                      borderColor: borderColor,
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (val) => setState(() => _notificationsEnabled = val),
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF4A89DC),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Switch funcional de modo oscuro conectado a main.dart
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeNotifier,
                      builder: (_, ThemeMode currentMode, __) {
                        bool isDarkModeOn = currentMode == ThemeMode.dark;
                        return _buildOptionItem(
                          icon: Icons.dark_mode,
                          iconColor: Colors.orange[300]!,
                          title: "Modo oscuro",
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          trailing: Switch(
                            value: isDarkModeOn,
                            onChanged: (val) {
                              themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                            },
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF4A89DC),
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 12),
                    _buildOptionItem(
                      icon: Icons.location_on,
                      iconColor: Colors.pinkAccent,
                      title: "Ubicación",
                      cardColor: cardColor,
                      textColor: textColor,
                      borderColor: borderColor,
                      trailing: Switch(
                        value: _locationEnabled,
                        onChanged: (val) => setState(() => _locationEnabled = val),
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF4A89DC),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOptionItem(
                      icon: Icons.bar_chart,
                      iconColor: Colors.blueGrey,
                      title: "Historial",
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      cardColor: cardColor,
                      textColor: textColor,
                      borderColor: borderColor,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildOptionItem(
                      icon: Icons.emoji_events,
                      iconColor: Colors.amber[600]!,
                      title: "Logros",
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      cardColor: cardColor,
                      textColor: textColor,
                      borderColor: borderColor,
                      onTap: () {},
                    ),
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

  Widget _buildStatItem(String value, String label, Color valueColor, Color labelColor) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    required Color cardColor,
    required Color textColor,
    required Color borderColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
