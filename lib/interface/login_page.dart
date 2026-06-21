import 'package:flutter/material.dart';
import '../application/login_service.dart'; 

class LoginPage extends StatefulWidget { 
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores para capturar lo que el usuario escribe
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginService _service = LoginService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Acceso SmartCart")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Correo electrónico"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Lógica de validación usando el servicio
                final email = _emailController.text;
                final password = _passwordController.text;

                if (_service.validateEmail(email) && _service.validatePassword(password)) {
                  print("¡Datos válidos!");
                } else {
                  print("Error: Datos incorrectos");
                }
              },
              child: const Text("Ingresar"),
            ),
          ],
        ),
      ),
    );
  }
}