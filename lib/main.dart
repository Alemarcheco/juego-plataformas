import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pantallas/inicio.dart';
import 'progreso.dart';
import 'sonido.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Progreso.cargar();
  await Sonido.iniciar();
  Sonido.musica('planicie');
  runApp(const PaquitoAdventure());
}

class PaquitoAdventure extends StatefulWidget {
  const PaquitoAdventure({super.key});

  @override
  State<PaquitoAdventure> createState() => _PaquitoAdventureState();
}

class _PaquitoAdventureState extends State<PaquitoAdventure>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // La música se para al salir de la app y sigue al volver
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Sonido.seguir();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      Sonido.pausar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paquito Adventure',
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
