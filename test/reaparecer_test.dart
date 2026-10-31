import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:paco_aventuras/datos/mundos.dart';
import 'package:paco_aventuras/juego/generador.dart';
import 'package:paco_aventuras/juego/motor.dart';

void main() {
  for (final control in [false, true]) {
    test('Paco reaparece de pie ${control ? "en la bandera" : "al principio"}', () {
      final malos = <String>[];
      for (final n in todosLosNiveles.where((n) => !n.bonus)) {
        final m = Motor(n);
        m.control = control;
        // Morir cayendo al vacío
        m.paco.y = 20;
        for (var i = 0; i < 60 * 3; i++) {
          m.actualizar(1 / 60);
        }
        final p = m.paco;
        final visible = p.y > 0 && p.y < Mapa.alto - 1;
        final enSuelo = p.enSuelo || n.tipo == TipoNivel.agua;
        if (m.estado != Estado.jugando || !visible || !enSuelo) {
          malos.add('${n.mundo}-${n.numero}: ${m.estado} '
              'x=${p.x.toStringAsFixed(1)} y=${p.y.toStringAsFixed(1)}');
        }
      }
      expect(malos, isEmpty);
    });
  }

  test('Los perros que lanzan avisan antes y la bomba del robot explota en 8 espinas', () {
    final n = todosLosNiveles.firstWhere((n) => n.mundo == 6 && n.numero == 1);
    final m = Motor(n);
    m.enemigos
      ..clear()
      ..add(Enemigo(TipoEnemigo.robot, m.paco.x + 5, m.paco.y, 0.95, 0.8, 0));
    m.mandos.izquierda = false;
    m.mandos.derecha = false;
    var avisoVisto = false;
    var bomba = false;
    var espinas = 0;
    for (var i = 0; i < 60 * 6; i++) {
      m.invencible = 10;
      m.actualizar(1 / 60);
      final e = m.enemigos.first;
      if (e.aviso > 0) {
        avisoVisto = true;
        expect(m.proyectiles.where((p) => p.tipo == TipoProyectil.bomba), isEmpty);
      }
      if (m.proyectiles.any((p) => p.tipo == TipoProyectil.bomba)) bomba = true;
      espinas = max(espinas, m.proyectiles.where((p) => p.tipo == TipoProyectil.espina).length);
    }
    expect(avisoVisto, isTrue);
    expect(bomba, isTrue);
    expect(espinas, 8);
  });
}
