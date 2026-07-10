import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/smartcart_theme.dart';
import '../../planning/application/basket_notifier.dart';
import '../../planning/application/basket_state.dart';
import '../../planning/domain/entities.dart';
import '../application/experience_notifier.dart';
import '../application/experience_state.dart';

class ValidationScreen extends ConsumerStatefulWidget {
  const ValidationScreen({super.key});

  @override
  ConsumerState<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends ConsumerState<ValidationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _reportPriceController = TextEditingController();
  final _manualTicketController = TextEditingController();
  final _manualReferenceController = TextEditingController();
  final _reviewController = TextEditingController();
  final _imagePicker = ImagePicker();
  int _selectedStars = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reportPriceController.dispose();
    _manualTicketController.dispose();
    _manualReferenceController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expState = ref.watch(experienceProvider);
    final basketState = ref.watch(basketProvider);

    ref.listen<ExperienceState>(experienceProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
        ref.read(experienceProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green),
        );
        ref.read(experienceProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Validación de Compra',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 4),
                  Text(
                    expState.hasJourneyContext
                        ? 'Tienda: ${expState.activeStoreName}'
                        : 'Finaliza un recorrido para validar y opinar',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text('Puntos: ${expState.walletBalance.points}',
                      style: const TextStyle(color: SmartCartTheme.primaryColor, fontWeight: FontWeight.bold)),
                  if (expState.savingsData != null)
                    Text(
                      'Ahorro del recorrido: S/ ${((expState.savingsData!['montoAhorro'] ?? expState.savingsData!['savingsAmount'] ?? 0) as num).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.teal, fontSize: 12),
                    ),
                  if (expState.trustProfile != null)
                    Text(
                      'Confianza tienda: ${expState.trustProfile!['trustScore'] ?? expState.trustProfile!['score'] ?? 'N/A'}',
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: SmartCartTheme.primaryColor,
              labelColor: SmartCartTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Por producto'),
                Tab(text: 'Por ticket'),
                Tab(text: 'Opinar'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductTab(expState, basketState),
                  _buildTicketTab(expState),
                  _buildReviewTab(expState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTab(ExperienceState expState, BasketState basketState) {
    final items = basketState.shoppingList.items;
    final selectedSku = expState.selectedProductSku;
    ProductItem? selectedItem;
    for (final item in items) {
      if (item.id == selectedSku) {
        selectedItem = item;
        break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Selecciona un producto de tu canasta',
              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('Tu canasta está vacía', style: TextStyle(color: Colors.grey))
          else
            ...items.map((item) {
              final isSelected = item.id == selectedSku;
              return Card(
                color: isSelected ? SmartCartTheme.primaryColor.withOpacity(0.1) : null,
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text('S/ ${item.price.toStringAsFixed(2)}'),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: SmartCartTheme.primaryColor) : null,
                  onTap: () {
                    ref.read(experienceProvider.notifier).selectProductForValidation(
                          sku: item.id,
                          name: item.name,
                          digitalPrice: item.price,
                        );
                  },
                ),
              );
            }),
          const SizedBox(height: 24),
          if (selectedItem != null) ...[
            _buildInfoRow('Producto', selectedItem.name),
            const SizedBox(height: 8),
            _buildInfoRow('Tienda', expState.activeStoreName ?? '—'),
            const SizedBox(height: 8),
            _buildInfoRow('Precio app', 'S/ ${selectedItem.price.toStringAsFixed(2)}', isPrice: true),
            const SizedBox(height: 16),
            TextField(
              controller: _reportPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio en góndola (solo para reportar)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: expState.isSubmitting || !expState.hasJourneyContext
                        ? null
                        : () => ref.read(experienceProvider.notifier).confirmProductPrice(),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: expState.isSubmitting || !expState.hasJourneyContext
                        ? null
                        : () {
                            final physical = double.tryParse(_reportPriceController.text);
                            if (physical == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ingresa el precio físico para reportar')),
                              );
                              return;
                            }
                            ref.read(experienceProvider.notifier).reportProductPriceError(physical);
                          },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Reportar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTicketTab(ExperienceState expState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: expState.ocrStatus == OcrStatus.loading ? null : _scanTicket,
            child: CustomPaint(
              painter: _DashedBorderPainter(),
              child: Container(
                height: 200,
                alignment: Alignment.center,
                child: expState.ocrStatus == OcrStatus.loading
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Analizando ticket...'),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            expState.ocrStatus == OcrStatus.success ? Icons.check_circle : Icons.camera_alt,
                            size: 48,
                            color: expState.ocrStatus == OcrStatus.success ? Colors.green : Colors.black54,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            expState.ocrStatus == OcrStatus.success
                                ? 'Ticket procesado'
                                : 'Toca para escanear ticket',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (expState.ocrStatus == OcrStatus.fallbackRequired) ...[
            const SizedBox(height: 24),
            const Text('Validación manual', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _manualReferenceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total referencia (app)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualTicketController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total pagado (ticket)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: expState.isSubmitting
                  ? null
                  : () {
                      final paid = double.tryParse(_manualTicketController.text);
                      final refTotal = double.tryParse(_manualReferenceController.text);
                      if (paid == null || refTotal == null) return;
                      ref.read(experienceProvider.notifier).submitManualTicketValidation(paid, refTotal);
                    },
              child: const Text('Enviar validación manual'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTab(ExperienceState expState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Califica la tienda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                icon: Icon(
                  star <= (_selectedStars > 0 ? _selectedStars : (expState.lastRating ?? 0))
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: expState.hasJourneyContext
                    ? () {
                        setState(() => _selectedStars = star);
                        ref.read(experienceProvider.notifier).submitRating(star);
                      }
                    : null,
              );
            }),
          ),
          const SizedBox(height: 24),
          const Text('Deja un comentario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Cuéntanos tu experiencia (mín. 10 caracteres)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: expState.isSubmitting || !expState.hasJourneyContext
                ? null
                : () => ref.read(experienceProvider.notifier).submitReview(_reviewController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: SmartCartTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Publicar reseña', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 32),
          const Text('Reseñas de la comunidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (expState.storeReviews.isEmpty)
            const Text('Aún no hay reseñas publicadas', style: TextStyle(color: Colors.grey))
          else
            ...expState.storeReviews.map(
              (r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(r.comentario),
                  subtitle: r.fechaCreacion != null ? Text(r.fechaCreacion!.toLocal().toString().substring(0, 16)) : null,
                ),
              ),
            ),
          if (expState.hasMoreReviews)
            TextButton(
              onPressed: expState.isLoadingReviews || expState.activeStoreId == null
                  ? null
                  : () => ref.read(experienceProvider.notifier).loadMoreStoreReviews(expState.activeStoreId!),
              child: expState.isLoadingReviews
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cargar más reseñas'),
            ),
        ],
      ),
    );
  }

  Future<void> _scanTicket() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      ref.read(experienceProvider.notifier).processTicket(image.path);
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 16)),
        Text(value,
            style: TextStyle(
                color: isPrice ? SmartCartTheme.primaryColor : Colors.black87,
                fontSize: 16,
                fontWeight: isPrice ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SmartCartTheme.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)));

    final metric = path.computeMetrics().first;
    const dashWidth = 8.0;
    const dashSpace = 8.0;
    var distance = 0.0;
    while (distance < metric.length) {
      canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
