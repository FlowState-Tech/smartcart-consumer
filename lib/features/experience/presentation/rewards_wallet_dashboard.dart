import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/smartcart_theme.dart';
import '../application/experience_notifier.dart';
import '../application/experience_state.dart';
import 'ocr_scanner_widget.dart';
import 'price_error_report_widget.dart';

class RewardsWalletDashboard extends ConsumerWidget {
  const RewardsWalletDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(experienceProvider);

    // Show snackbar if there's an error message
    ref.listen<ExperienceState>(experienceProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage && next.ocrStatus != OcrStatus.fallbackRequired) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Recompensas & Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Points Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SmartCartTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  const Text('Tus Puntos', style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    '${state.walletBalance.points}',
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(experienceProvider.notifier).generateVoucher(),
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Canjear Vale (100 pts)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: SmartCartTheme.primaryColor,
                    ),
                  )
                ],
              ),
            ),
            
            if (state.activeVoucher != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: SmartCartTheme.accentColor, // Lima Suave
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('¡Vale Generado!', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(state.activeVoucher!, style: const TextStyle(fontSize: 24, letterSpacing: 4)),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            Text('Tus Insignias', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (state.badges.isEmpty)
              const Text('Aún no tienes insignias. ¡Valida precios para ganar puntos!')
            else
              Row(
                children: state.badges.map((badge) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: SmartCartTheme.secondaryColor,
                        child: Icon(Icons.explore, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 4),
                      Text(badge.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )).toList(),
              ),

            const SizedBox(height: 32),
            Text('Acciones de Comunidad', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Escanear Ticket de Compra'),
              subtitle: const Text('Gana 25 puntos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OcrScannerWidget()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text('Reportar Oferta Falsa'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showModalBottomSheet(
                  context: context, 
                  isScrollControlled: true,
                  builder: (_) => Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: const PriceErrorReportWidget(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Validar Precio en Tienda'),
              subtitle: const Text('Simula estar a < 500m'),
              trailing: const Icon(Icons.add_circle, color: Colors.green),
              onTap: () {
                // Mocking GPS validation success (distance 0m)
                ref.read(experienceProvider.notifier).validateInStorePrice(-12.0, -77.0, -12.0, -77.0);
              },
            )
          ],
        ),
      ),
    );
  }
}
