import 'package:flutter/material.dart';

import '../datos/logros.dart';
import '../datos/skins.dart';
import '../progreso.dart';
import 'comunes.dart';

/// Tienda de trajes: se pagan con los pescados de los niveles.
class PantallaTienda extends StatefulWidget {
  const PantallaTienda({super.key});

  @override
  State<PantallaTienda> createState() => _PantallaTiendaState();
}

class _PantallaTiendaState extends State<PantallaTienda> {
  Future<void> _elegir(Skin s) async {
    if (Progreso.comprados.contains(s.id)) {
      await Progreso.ponerse(s);
    } else if (!await Progreso.comprar(s)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Te faltan ${s.precio - Progreso.monedero} pescados para ${s.nombre}.'),
      ));
      return;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14202E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text('Tienda de trajes',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  const Icon(Icons.set_meal_rounded, color: Color(0xFFFFC93C)),
                  const SizedBox(width: 6),
                  Text('${Progreso.monedero}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                children: [
                  for (final s in skins) _tarjeta(s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Traje de premio aún sin ganar: qué hay que hacer y cuánto falta.
  Widget _premio(Logro l) {
    final avance = Progreso.avance(l).clamp(0, l.meta);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC93C), size: 18),
            const SizedBox(width: 4),
            Flexible(
              child: Text(l.descripcion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ),
          ],
        ),
        if (l.meta > 1) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: avance / l.meta,
              minHeight: 8,
              color: const Color(0xFFFFC93C),
              backgroundColor: Colors.black38,
            ),
          ),
          const SizedBox(height: 2),
          Text('$avance de ${l.meta}',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ],
    );
  }

  Widget _tarjeta(Skin s) {
    final tiene = Progreso.comprados.contains(s.id);
    final puesto = Progreso.skinActual == s.id;
    final alcanza = Progreso.monedero >= s.precio;
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2D40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: puesto ? const Color(0xFFF59A33) : Colors.white12, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RetratoPaco(tamano: 96, skin: s),
          Text(s.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          if (s.logro != null && !tiene)
            _premio(logros.firstWhere((l) => l.id == s.logro))
          else if (puesto)
            const Text('Puesto',
                style: TextStyle(color: Color(0xFFF59A33), fontWeight: FontWeight.w800))
          else
            FilledButton(
              onPressed: tiene || alcanza ? () => _elegir(s) : null,
              child: tiene
                  ? const Text('Ponérselo')
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.set_meal_rounded, size: 18),
                        const SizedBox(width: 4),
                        Text('${s.precio}'),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
