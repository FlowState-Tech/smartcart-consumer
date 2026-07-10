import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/smartcart_theme.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crear Cuenta',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 32),
                Text('Nombre de usuario', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: 'Tu nombre de usuario',
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
                    filled: true,
                    fillColor: Colors.transparent,
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SmartCartTheme.primaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Email', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: 'correo@ejemplo.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
                    filled: true,
                    fillColor: Colors.transparent,
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SmartCartTheme.primaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Contraseña', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
                    filled: true,
                    fillColor: Colors.transparent,
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SmartCartTheme.primaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (val) {
                        setState(() => _acceptedTerms = val ?? false);
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: BorderSide(color: SmartCartTheme.primaryColor),
                    ),
                    Expanded(
                      child: Text(
                        'Al registrarte aceptas los Términos y Condiciones y la Política de Privacidad de SmartCart.',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState is AuthLoading
                      ? null
                      : () async {
                          if (!_acceptedTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
                            );
                            return;
                          }
                          final username = _nameController.text.trim();
                          if (username.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ingresa un nombre de usuario')),
                            );
                            return;
                          }
                          if (_passwordController.text.length < 8) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres')),
                            );
                            return;
                          }
                          final email = _emailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ingresa un correo electrónico válido')),
                            );
                            return;
                          }
                          try {
                            await ref.read(authProvider.notifier).signUp(
                                  email,
                                  _passwordController.text,
                                  fullName: username,
                                );
                            if (!context.mounted) return;
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AuthNotifier.cleanError(e)),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmartCartTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: authState is AuthLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text('Registrarse', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya tienes cuenta? ', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text('Inicia sesión', style: TextStyle(color: SmartCartTheme.primaryColor)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
