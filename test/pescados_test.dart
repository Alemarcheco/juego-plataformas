import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:paco_aventuras/datos/mundos.dart';
import 'package:paco_aventuras/juego/generador.dart';
import 'package:paco_aventuras/juego/motor.dart';

/// Recorre todo el nivel con la física real (saltando de un sitio firme a
/// otro, en las dos direcciones) y devuelve los pescados que quedan sin
/// coger: esos son imposibles.
List<(int, int)> pescadosImposibles(Nivel n) {
  if (n.tipo == TipoNivel.agua) return _imposiblesNadando(generarMapa(n));
  final m = Motor(n);
  m.enemigos.clear();
  const dt = 1 / 60;
  for (var i = 0; i < 240 && !m.paco.enSuelo; i++) {
    m.actualizar(dt);
  }

  ({double x, double y})? simular(double x, double y, int dir, bool carrerilla,
      int pasosAntes, int framesSalto) {
    m.estado = Estado.jugando;
    m.invencible = 100;
    m.paco
      ..x = x
      ..y = y
      ..vx = carrerilla ? dir * 7.5 : 0
      ..vy = 0
      ..enSuelo = true;
    m.mandos
      ..izquierda = dir < 0
      ..derecha = dir > 0
      ..salto = false;
    m.actualizar(dt);
    for (var i = 0; i < pasosAntes; i++) {
      m.actualizar(dt);
    }
    for (var i = 0; i < 300; i++) {
      m.mandos.salto = i < framesSalto;
      m.actualizar(dt);
      if (m.estado != Estado.jugando) return null;
      if (i > 2 && m.paco.enSuelo) return (x: m.paco.x, y: m.paco.y);
    }
    return null;
  }

  final visto = <String>{};
  final cola = Queue<({double x, double y})>();
  cola.add((x: m.paco.x, y: m.paco.y));
  while (cola.isNotEmpty) {
    final e = cola.removeFirst();
    final clave = '${(e.x * 2).round()},${e.y.round()}';
    if (!visto.add(clave)) continue;
    for (final dir in [1, -1]) {
      for (final carrerilla in [true, false]) {
        for (final pasos in [0, 4]) {
          for (final salto in [0, 6, 12, 40]) {
            final r = simular(e.x, e.y, dir, carrerilla, pasos, salto);
            if (r != null) cola.add(r);
          }
        }
      }
    }
  }
  return [
    for (var x = 0; x < m.mapa.ancho; x++)
      for (var y = 0; y < Mapa.alto; y++)
        if (m.mapa.casillas[x][y] == Casilla.moneda) (x, y)
  ];
}

List<(int, int)> _imposiblesNadando(Mapa mapa) {
  bool libre(int x, int y) =>
      x >= 0 && x < mapa.ancho && y >= 1 && y < Mapa.alto &&
      !esSolida(mapa.en(x, y)) && !esSolida(mapa.en(x, y - 1));
  final visto = <int>{};
  final cola = Queue<(int, int)>();
  cola.add((mapa.inicioX.floor(), mapa.inicioY.floor()));
  while (cola.isNotEmpty) {
    final (x, y) = cola.removeFirst();
    if (!libre(x, y) || !visto.add(x * 100 + y)) continue;
    cola.addAll([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]);
  }
  return [
    for (var x = 0; x < mapa.ancho; x++)
      for (var y = 0; y < Mapa.alto; y++)
        if (mapa.casillas[x][y] == Casilla.moneda &&
            !visto.contains(x * 100 + y) &&
            !visto.contains(x * 100 + y + 1))
          (x, y)
  ];
}

void main() {
  for (final n in todosLosNiveles) {
    test('Todos los pescados del ${n.titulo} se pueden coger', () {
      final malos = pescadosImposibles(n);
      expect(malos, isEmpty, reason: '${malos.length} pescados imposibles: $malos');
    });
  }
}
