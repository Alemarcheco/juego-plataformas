import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paco_aventuras/datos/creados.dart';
import 'package:paco_aventuras/juego/generador.dart';
import 'package:paco_aventuras/juego/motor.dart';

void main() {
  test('Un nivel creado se guarda y se carga igual', () {
    final n = NivelCreado.nuevo('1', 'Prueba')
      ..tema = 'nieve'
      ..musica = 'jefe'
      ..agua = true
      ..controlX = 30
      ..controlY = 11;
    n.casillas[10][8] = Casilla.ladrillo;
    n.enemigos.add(const Aparicion(TipoEnemigo.robot, 20.03, 12));
    final otra = NivelCreado.fromJson(
        jsonDecode(jsonEncode(n.toJson())) as Map<String, dynamic>);
    expect(jsonEncode(otra.toJson()), jsonEncode(n.toJson()));
    expect(otra.casillas[10][8], Casilla.ladrillo);
    expect(otra.enemigos.single.tipo, TipoEnemigo.robot);
  });

  test('Un nivel nuevo se puede jugar hasta la meta', () {
    final n = NivelCreado.nuevo('1', 'Prueba');
    n.cambiarAncho(40);
    final m = Motor(n.nivel, crearMapa: n.mapa);
    m.mandos.derecha = true;
    for (var i = 0; i < 60 * 30 && m.estado == Estado.jugando; i++) {
      m.actualizar(1 / 60);
    }
    expect(m.estado, Estado.ganado);
  });

  test('Al morir en un nivel creado se vuelve a la bandera', () {
    final n = NivelCreado.nuevo('1', 'Prueba')
      ..controlX = 20
      ..controlY = 11;
    final m = Motor(n.nivel, crearMapa: n.mapa);
    m.control = true;
    m.paco.y = 20;
    for (var i = 0; i < 60 * 3; i++) {
      m.actualizar(1 / 60);
    }
    expect(m.estado, Estado.jugando);
    expect(m.paco.x, 20);
    expect(m.paco.enSuelo, isTrue);
  });
}
