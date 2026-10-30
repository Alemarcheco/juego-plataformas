import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:paco_aventuras/datos/mundos.dart';
import 'package:paco_aventuras/juego/generador.dart';
import 'package:paco_aventuras/juego/motor.dart';

/// Comprueba con la física real del juego que se puede llegar a la meta
/// (o a la arena del jefe) saltando de un sitio firme a otro.
/// Los enemigos se quitan: solo se comprueba el terreno.
({bool llega, double masLejos}) recorrible(Nivel n) {
  if (n.tipo == TipoNivel.agua) return nadable(generarMapa(n));
  final m = Motor(n);
  m.enemigos.clear();
  final objetivo = m.mapa.arenaX != null ? m.mapa.arenaX! + 2 : m.mapa.metaX;
  const dt = 1 / 60;

  // Deja caer a Paco hasta que pise suelo.
  void asentar() {
    for (var i = 0; i < 240 && !m.paco.enSuelo; i++) {
      m.actualizar(dt);
    }
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
      if (m.estado != Estado.jugando) {
        return m.estado == Estado.ganado ? (x: objetivo + 1, y: m.paco.y) : null;
      }
      if (m.paco.x >= objetivo) return (x: m.paco.x, y: m.paco.y);
      if (i > 2 && m.paco.enSuelo) return (x: m.paco.x, y: m.paco.y);
    }
    return null;
  }

  asentar();
  final visto = <String>{};
  final cola = Queue<({double x, double y})>();
  cola.add((x: m.paco.x, y: m.paco.y));
  var masLejos = m.paco.x;
  while (cola.isNotEmpty) {
    final e = cola.removeFirst();
    final clave = '${(e.x * 2).round()},${e.y.round()}';
    if (!visto.add(clave)) continue;
    if (e.x >= objetivo) return (llega: true, masLejos: e.x);
    if (e.x > masLejos) masLejos = e.x;
    for (final dir in [1, -1]) {
      for (final carrerilla in [true, false]) {
        for (final pasos in [0, 4]) {
          for (final salto in [0, 6, 12, 40]) {
            final r = simular(e.x, e.y, dir, carrerilla, pasos, salto);
            if (r == null) continue;
            if (r.x >= objetivo) return (llega: true, masLejos: r.x);
            cola.add(r);
          }
        }
      }
    }
  }
  return (llega: false, masLejos: masLejos);
}

/// Bajo el agua Paco nada a donde quiera: basta un pasillo de 2 casillas de alto.
({bool llega, double masLejos}) nadable(Mapa mapa) {
  bool libre(int x, int y) =>
      x >= 0 && x < mapa.ancho && y >= 1 && y < Mapa.alto &&
      !esSolida(mapa.en(x, y)) && !esSolida(mapa.en(x, y - 1));
  final objetivo = (mapa.arenaX ?? mapa.metaX).floor();
  final visto = <int>{};
  final cola = Queue<(int, int)>();
  cola.add((mapa.inicioX.floor(), mapa.inicioY.floor()));
  var masLejos = 0;
  while (cola.isNotEmpty) {
    final (x, y) = cola.removeFirst();
    if (!libre(x, y) || !visto.add(x * 100 + y)) continue;
    if (x > masLejos) masLejos = x;
    if (x >= objetivo) return (llega: true, masLejos: x.toDouble());
    cola.addAll([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]);
  }
  return (llega: false, masLejos: masLejos.toDouble());
}

void main() {
  test('Hay 80 niveles y 4 secretos', () {
    expect(todosLosNiveles.length, 84);
    for (var i = 0; i < 84; i++) {
      expect(todosLosNiveles[i].indice, i);
    }
  });

  test('Yendo hacia atrás en el 9-5 se encuentra el mundo secreto', () {
    final n = todosLosNiveles.firstWhere((n) => n.mundo == 9 && n.numero == 5);
    final m = Motor(n);
    m.enemigos.clear();
    for (var i = 0; i < 60 * 6 && m.estado == Estado.jugando; i++) {
      m.mandos.izquierda = true;
      m.actualizar(1 / 60);
    }
    expect(m.secretoEncontrado, isTrue);
  });

  test('Los perros especiales disparan y no rompen nada', () {
    for (final n in todosLosNiveles) {
      final m = Motor(n);
      for (var i = 0; i < 60 * 20; i++) {
        m.mandos.derecha = i % 200 < 150;
        m.mandos.salto = i % 40 < 10;
        m.actualizar(1 / 60);
      }
    }
  });

  for (final n in todosLosNiveles) {
    test('Nivel ${n.mundo}-${n.numero} se puede recorrer', () {
      final mapa = generarMapa(n);
      expect(mapa.metaX, greaterThan(20));
      final r = recorrible(n);
      expect(r.llega, isTrue,
          reason: 'Solo se llega hasta x=${r.masLejos.toStringAsFixed(1)} '
              'de ${mapa.ancho}');
    });
  }

  for (final n in todosLosNiveles.where((n) => n.jefe != null)) {
    test('Se puede vencer al jefe del nivel ${n.mundo}-${n.numero}', () {
      final m = Motor(n);
      m.enemigos.clear();
      m.paco.x = m.mapa.arenaX! + 3;
      m.paco.y = m.mapa.sueloArena - 1;
      for (var i = 0; i < 30; i++) {
        m.actualizar(1 / 60);
      }
      expect(m.puertaCerrada, isTrue);
      final jefe = m.jefe!;
      for (var golpe = 0; golpe < 100 && m.estado == Estado.jugando; golpe++) {
        // Paco cae sobre la cabeza del jefe
        m.vidas = 3;
        m.invencible = 0;
        m.paco
          ..x = jefe.centroX - 0.4
          ..y = jefe.y - 0.95
          ..vy = 4;
        for (var i = 0; i < 70 && m.estado == Estado.jugando; i++) {
          m.actualizar(1 / 60);
          if (jefe.invencible > 0.9) break;
        }
      }
      expect(m.estado, Estado.ganado, reason: "vidas jefe ${jefe.vidas} x=${jefe.x} y=${jefe.y} paco ${m.paco.x},${m.paco.y}");
      for (var i = 0; i < 120; i++) {
        m.actualizar(1 / 60);
      }
      expect(m.terminado, isTrue);
    });
  }
}
