import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pantallas/inicio.dart';
import 'progreso.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Progreso.cargar();
  runApp(const AventurasDePaco());
}

class AventurasDePaco extends StatelessWidget {
  const AventurasDePaco({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Las aventuras de Paco',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF59A33), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const PantallaInicio(),
    );
  }
}
