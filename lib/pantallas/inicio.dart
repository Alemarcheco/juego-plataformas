import 'package:flutter/material.dart';

import '../datos/mundos.dart';
import '../juego/pintor.dart';
import '../progreso.dart';
import '../version.dart';
import 'comunes.dart';
import 'creador.dart';
import 'mapa.dart';
import 'tienda.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _baile = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  @override
  void dispose() {
    _baile.dispose();
    super.dispose();
  }

  Future<void> _perfil(String id) async {
    if (id == Progreso.perfil) return;
    await Progreso.elegirPerfil(id);
    if (mounted) setState(() {});
  }

  Future<void> _ir(Widget pantalla) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => pantalla));
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
        child: Stack(
          children: [
            // Gato bailando tecktonik en el cielo
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _baile,
                builder: (_, _) =>
                    CustomPaint(painter: _Baile(_baile.value * 60)),
              ),
            ),
            SafeArea(
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
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '10 mundos · 80 niveles · ¡vence al Perro Supremo! · versión $versionJuego',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2A3A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _perfiles(),
                      const SizedBox(height: 8),
                      const BarraProgreso(),
                      const SizedBox(height: 14),
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
            Positioned(
              right: 12,
              bottom: 8,
              child: Text(
                'Versión $versionJuego',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Los dos perfiles para elegir quién juega.
  Widget _perfiles() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        '¿Quién juega?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1F2A3A),
        ),
      ),
      const SizedBox(width: 10),
      for (final p in perfiles)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            avatar: const Icon(Icons.person_rounded),
            label: Text(
              p.nombre,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            selected: Progreso.perfil == p.id,
                showCheckmark: false,
            onSelected: (_) => _perfil(p.id),
          ),
        ),
    ],
  );
}

/// Barra del 0 al 100 %: todos los niveles (también los secretos) con
/// todos sus pescados.
class BarraProgreso extends StatelessWidget {
  final double ancho;
  const BarraProgreso({super.key, this.ancho = 320});

  @override
  Widget build(BuildContext context) {
    final p = Progreso.porcentaje();
    final texto = p >= 99.95 ? '100' : p.toStringAsFixed(p < 10 ? 1 : 0);
    return Tooltip(
      message:
          'Termina todos los niveles con todos los pescados, el mundo '
          'secreto y el nivel secreto para llegar al 100 %',
      triggerMode: TooltipTriggerMode.tap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: ancho,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: p / 100,
                minHeight: 14,
                color: p >= 99.95
                    ? const Color(0xFFFFC93C)
                    : const Color(0xFFF59A33),
                backgroundColor: Colors.black26,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$texto %',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1))],
            ),
          ),
        ],
      ),
    );
  }
}

class _Baile extends CustomPainter {
  final double t;
  _Baile(this.t);

  @override
  void paint(Canvas c, Size size) =>
      gatoBailando(c, Size(size.width, size.height * 0.75), t, Temas.cielo,
          donde: 0.87, alfa: 0.6);

  @override
  bool shouldRepaint(covariant _Baile old) => old.t != t;
}
