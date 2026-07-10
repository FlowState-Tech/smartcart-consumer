import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../application/experience_notifier.dart';

class PriceErrorReportWidget extends ConsumerStatefulWidget {
  const PriceErrorReportWidget({super.key});

  @override
  ConsumerState<PriceErrorReportWidget> createState() => _PriceErrorReportWidgetState();
}

class _PriceErrorReportWidgetState extends ConsumerState<PriceErrorReportWidget> {
  final ImagePicker _picker = ImagePicker();
  final _digitalPriceController = TextEditingController();
  final _physicalPriceController = TextEditingController();
  final _productIdController = TextEditingController();
  String? _imagePath;

  @override
  void dispose() {
    _digitalPriceController.dispose();
    _physicalPriceController.dispose();
    _productIdController.dispose();
    super.dispose();
  }

  Future<void> _attachImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(experienceProvider.select((s) => s.isSubmitting));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Reportar publicidad falsa', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _productIdController,
            decoration: const InputDecoration(
              labelText: 'SKU / ID producto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _digitalPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio publicado en app',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _physicalPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio real en tienda',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _attachImage,
            icon: Icon(_imagePath != null ? Icons.check_circle : Icons.image),
            label: Text(_imagePath != null ? 'Evidencia adjuntada' : 'Adjuntar foto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _imagePath != null ? Colors.green : null,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    final productoId = _productIdController.text.trim();
                    final digital = double.tryParse(_digitalPriceController.text);
                    final physical = double.tryParse(_physicalPriceController.text);
                    if (productoId.isEmpty || digital == null || physical == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Completa todos los campos')),
                      );
                      return;
                    }
                    await ref.read(experienceProvider.notifier).reportOfferIssue(
                          productoId: productoId,
                          precioDigital: digital,
                          precioFisico: physical,
                          evidenceImagePath: _imagePath,
                        );
                    if (context.mounted) Navigator.of(context).pop();
                  },
            child: isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('ENVIAR REPORTE'),
          ),
        ],
      ),
    );
  }
}
