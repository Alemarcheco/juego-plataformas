import 'package:flutter/material.dart';

import 'comunes.dart';
import 'mapa.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

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
                  const RetratoPaco(tamano: 130),
                  const SizedBox(height: 10),
                  Text(
                    'Las aventuras de Paco',
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
                  BotonJuego(
                    texto: 'JUGAR',
                    icono: Icons.play_arrow_rounded,
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PantallaMapa())),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
