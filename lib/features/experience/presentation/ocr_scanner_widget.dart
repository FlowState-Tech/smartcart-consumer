import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../application/experience_notifier.dart';
import '../application/experience_state.dart';

class OcrScannerWidget extends ConsumerStatefulWidget {
  const OcrScannerWidget({super.key});

  @override
  ConsumerState<OcrScannerWidget> createState() => _OcrScannerWidgetState();
}

class _OcrScannerWidgetState extends ConsumerState<OcrScannerWidget> {
  final ImagePicker _picker = ImagePicker();
  final _manualTicketController = TextEditingController();
  final _manualReferenceController = TextEditingController();

  @override
  void dispose() {
    _manualTicketController.dispose();
    _manualReferenceController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      ref.read(experienceProvider.notifier).processTicket(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(experienceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Escáner de Ticket')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.ocrStatus == OcrStatus.idle || state.ocrStatus == OcrStatus.success) ...[
                Icon(
                  state.ocrStatus == OcrStatus.success ? Icons.check_circle : Icons.document_scanner,
                  size: 100,
                  color: state.ocrStatus == OcrStatus.success ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 24),
                if (state.ocrStatus == OcrStatus.success)
                  const Text('¡Ticket procesado con éxito! +25 pts',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar foto al ticket'),
                ),
              ],
              if (state.ocrStatus == OcrStatus.loading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('Analizando ticket con OCR...'),
              ],
              if (state.ocrStatus == OcrStatus.fallbackRequired) ...[
                const Icon(Icons.warning, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'Error de lectura',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 32),
                const Text('Validación manual (fallback)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
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
                  onPressed: state.isSubmitting
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
        ),
      ),
    );
  }
}
