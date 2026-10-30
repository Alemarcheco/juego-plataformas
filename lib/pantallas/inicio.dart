import 'package:flutter/material.dart';

import '../progreso.dart';
import 'comunes.dart';
import 'creador.dart';
import 'mapa.dart';
import 'tienda.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  Future<void> _ir(Widget pantalla) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) setState(() {}); // por si cambió el traje de Paco
  }

  Future<void> _creador() async {
    if (!Progreso.creador) {
      final comprar = await pedirCreador(context);
      if (!comprar || !mounted) return;
    }
    await _ir(const PantallaCreador());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4FA8F0), Color(0xFFBFE6FF), Color(0xFF5DBB3F)],
            stops: [0, 0.75, 0.75],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RetratoPaco(tamano: 130, skin: Progreso.skin),
                  const SizedBox(height: 10),
                  Text(
                    'Paquito Adventure',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            offset: const Offset(3, 3),
                            blurRadius: 0),
                      ],
                    ),
                  ),
                  const Text(
                    '10 mundos · 80 niveles · ¡vence al Perro Supremo!',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1F2A3A),
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 14,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      BotonJuego(
                        texto: 'JUGAR',
                        icono: Icons.play_arrow_rounded,
                        onPressed: () => _ir(const PantallaMapa()),
                      ),
                      BotonJuego(
                        texto: 'CREADOR',
                        icono: Progreso.creador
                            ? Icons.construction_rounded
                            : Icons.lock_rounded,
                        color: const Color(0xFF3FAE5A),
                        onPressed: _creador,
                      ),
                      BotonJuego(
                        texto: 'TIENDA',
                        icono: Icons.storefront_rounded,
                        color: const Color(0xFF4A90D9),
                        onPressed: () => _ir(const PantallaTienda()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const InterruptoresSonido(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
