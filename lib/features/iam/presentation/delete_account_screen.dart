import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_notifier.dart';
import '../../planning/application/basket_notifier.dart';
import '../../journey/application/route_notifier.dart';
import '../../experience/application/experience_notifier.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _validationController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _validationController.addListener(() {
      setState(() {
        _isButtonEnabled = _validationController.text == 'ELIMINAR';
      });
    });
  }

  @override
  void dispose() {
    _validationController.dispose();
    super.dispose();
  }

  Future<void> _onDelete() async {
    if (_isButtonEnabled) {
      await ref.read(basketProvider.notifier).clearAllLocalData();
      ref.read(routeProvider.notifier).resetRoute();
      await ref.read(experienceProvider.notifier).clearLocalData();
      await ref.read(authProvider.notifier).deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos locales eliminados y sesión cerrada.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baja de Servicio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 24),
            Text(
              '¿Estás seguro de que deseas eliminar tu cuenta?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Se eliminarán tus datos locales (canasta, recompensas, preferencias) y se cerrará la sesión. '
              'La cuenta en el servidor no se elimina automáticamente porque el backend aún no expone ese endpoint.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Text(
              'Para confirmar, escribe la palabra "ELIMINAR" abajo:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _validationController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'ELIMINAR',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isButtonEnabled ? _onDelete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('ELIMINAR CUENTA DEFINITIVAMENTE'),
            ),
          ],
        ),
      ),
    );
  }
}
