import 'package:flutter/material.dart';
import 'screens/registrar_cliente_screen.dart';

void main() {
  runApp(const PeluqueriaApp());
}

class PeluqueriaApp extends StatelessWidget {
  const PeluqueriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salón de belleza',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const RegistrarClienteScreen(),
    );
  }
}
