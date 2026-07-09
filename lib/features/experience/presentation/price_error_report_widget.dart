import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PriceErrorReportWidget extends StatefulWidget {
  const PriceErrorReportWidget({super.key});

  @override
  State<PriceErrorReportWidget> createState() => _PriceErrorReportWidgetState();
}

class _PriceErrorReportWidgetState extends State<PriceErrorReportWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _hasImage = false;

  Future<void> _attachImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() { _hasImage = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Reportar Publicidad Falsa', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Describe la inconsistencia de precio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _attachImage,
            icon: Icon(_hasImage ? Icons.check_circle : Icons.image),
            label: Text(_hasImage ? 'Imagen Adjuntada' : 'Adjuntar Evidencia (Foto)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _hasImage ? Colors.green : null,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reporte enviado para revisión manual. ¡Gracias por ayudar a la comunidad!')),
              );
            },
            child: const Text('ENVIAR REPORTE'),
          )
        ],
      ),
    );
  }
}
