import 'package:flutter/material.dart';

import '../datos/mundos.dart';
import '../progreso.dart';
import 'inicio.dart';
import 'juego.dart';
import 'tienda.dart';

class PantallaMapa extends StatefulWidget {
  const PantallaMapa({super.key});

  @override
  State<PantallaMapa> createState() => _PantallaMapaState();
}

class _PantallaMapaState extends State<PantallaMapa> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Lleva el mapa al mundo donde va Paco
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mundo = Progreso.desbloqueado ~/ 8;
      if (_scroll.hasClients) {
        _scroll.jumpTo((mundo * 292.0).clamp(0, _scroll.position.maxScrollExtent));
      }
    });
  }

  Future<void> _jugar(Nivel n) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PantallaJuego(nivel: n)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14202E),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text('Elige un nivel',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  const BarraProgreso(ancho: 160),
                  const SizedBox(width: 16),
                  const Icon(Icons.set_meal_rounded, color: Color(0xFFFFC93C)),
                  const SizedBox(width: 6),
                  Text(
                    '${Progreso.monedero}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const PantallaTienda()));
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Tienda'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                itemCount: mundos.length + 1,
                itemBuilder: (_, i) => i < mundos.length
                    ? _TarjetaMundo(mundo: mundos[i], alJugar: _jugar)
                    : Progreso.secreto
                        ? _TarjetaMundo(mundo: mundoSecreto, alJugar: _jugar)
                        : const _TarjetaOculta(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaMundo extends StatelessWidget {
  final Mundo mundo;
  final void Function(Nivel) alJugar;
  const _TarjetaMundo({required this.mundo, required this.alJugar});

  @override
  Widget build(BuildContext context) {
    final niveles = mundo.niveles;
    final bloqueado = !Progreso.abierto(niveles.first.indice);
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2D40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mundo.color, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: mundo.color,
                child: Text('${mundo.numero}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mundo.nombre,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                    Text(mundo.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              if (bloqueado) const Icon(Icons.lock_rounded, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final n in niveles) _BotonNivel(nivel: n, alJugar: alJugar),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hueco del mundo secreto mientras no se ha encontrado.
class _TarjetaOculta extends StatelessWidget {
  const _TarjetaOculta();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 3),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('?', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white38)),
          Text('Mundo secreto', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BotonNivel extends StatelessWidget {
  final Nivel nivel;
  final void Function(Nivel) alJugar;
  const _BotonNivel({required this.nivel, required this.alJugar});

  @override
  Widget build(BuildContext context) {
    final abierto = Progreso.abierto(nivel.indice);
    final hecho = Progreso.completado(nivel.indice);
    final color = abierto ? nivel.tema.cesped : const Color(0xFF3A4658);
    final fondo = abierto ? nivel.tema.cieloArriba : const Color(0xFF2A3546);
    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: abierto ? () => alJugar(nivel) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(bottom: BorderSide(color: color, width: 6)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!abierto)
                const Icon(Icons.lock_rounded, color: Colors.white38, size: 20)
              else
                Text('${nivel.numero}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              offset: const Offset(1, 1))
                        ])),
              if (nivel.jefe != null && abierto)
                const Positioned(
                  top: 3,
                  right: 4,
                  child: Icon(Icons.pets_rounded, size: 13, color: Colors.white),
                ),
              if (hecho)
                const Positioned(
                  bottom: 6,
                  child: Icon(Icons.star_rounded,
                      size: 14, color: Color(0xFFFFC93C)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
