import 'package:flutter_test/flutter_test.dart';
import 'package:paco_aventuras/datos/creados.dart';
import 'package:paco_aventuras/juego/generador.dart';
import 'package:paco_aventuras/juego/motor.dart';

Motor _motor() {
  final n = NivelCreado.nuevo('1', 'Dos')..cambiarAncho(60);
  // Un hueco en el medio
  for (var x = 25; x < 28; x++) {
    for (var y = 12; y < Mapa.alto; y++) {
      n.casillas[x][y] = Casilla.vacio;
    }
  }
  return Motor(n.nivel, crearMapa: n.mapa, dosJugadores: true);
}

void main() {
  test('Los dos gatos empiezan juntos y llegan a la meta', () {
    final m = _motor();
    expect(m.jugadores, hasLength(2));
    for (final j in m.jugadores) {
      j.mandos.derecha = true;
      j.mandos.salto = true; // saltan todo el rato para pasar el hueco
    }
    for (var i = 0; i < 60 * 30 && m.estado == Estado.jugando; i++) {
      for (final j in m.jugadores) {
        j.mandos.salto = i % 40 < 30;
      }
      m.actualizar(1 / 60);
    }
    expect(m.estado, Estado.ganado);
  });

  test('Si se cae uno, vuelve junto al otro sin reiniciar el nivel', () {
    final m = _motor();
    final caido = m.jugadores[1];
    caido.cuerpo.y = 20;
    m.actualizar(1 / 60);
    expect(caido.vivo, isFalse);
    expect(m.estado, Estado.jugando);
    for (var i = 0; i < 60 * 3; i++) {
      m.actualizar(1 / 60);
    }
    expect(caido.vivo, isTrue);
    expect((caido.cuerpo.x - m.jugadores[0].cuerpo.x).abs(), lessThan(2));
  });

  test('Si se caen los dos, se vuelve a empezar', () {
    final m = _motor();
    for (final j in m.jugadores) {
      j.cuerpo.y = 20;
    }
    m.actualizar(1 / 60);
    expect(m.estado, Estado.muerto);
    for (var i = 0; i < 60 * 3; i++) {
      m.actualizar(1 / 60);
    }
    expect(m.estado, Estado.jugando);
    expect(m.jugadores.every((j) => j.vivo && j.cuerpo.y < 12), isTrue);
  });

  test('Ningún gato se sale de la pantalla', () {
    final m = _motor();
    m.jugadores[0].mandos.derecha = true;
    for (var i = 0; i < 60 * 6; i++) {
      m.actualizar(1 / 60);
      for (final j in m.jugadores.where((j) => j.vivo)) {
        expect(j.cuerpo.x, greaterThanOrEqualTo(m.camX - 0.01));
        expect(j.cuerpo.x + j.cuerpo.w, lessThanOrEqualTo(m.camX + m.anchoVista + 0.01));
      }
    }
  });
}
