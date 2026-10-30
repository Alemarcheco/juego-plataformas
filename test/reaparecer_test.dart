import 'package:flutter_test/flutter_test.dart';
import 'package:paco_aventuras/datos/mundos.dart';
import 'package:paco_aventuras/juego/generador.dart';
import 'package:paco_aventuras/juego/motor.dart';

void main() {
  for (final control in [false, true]) {
    test('Paco reaparece de pie ${control ? "en la bandera" : "al principio"}', () {
      final malos = <String>[];
      for (final n in todosLosNiveles) {
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
}
