import 'package:flutter_test/flutter_test.dart';
import 'package:paco_aventuras/datos/creados.dart';
import 'package:paco_aventuras/datos/mundos.dart';
import 'package:paco_aventuras/juego/generador.dart';
import 'package:paco_aventuras/juego/motor.dart';

/// Pisa al jefe hasta vencerlo (como en niveles_test).
void vencerJefe(Motor m) {
  final jefe = m.jefe!;
  for (var golpe = 0; golpe < 100 && jefe.derrotado == 0 && m.estado == Estado.jugando; golpe++) {
    m.vidas = 3;
    m.invencible = 0;
    m.proyectiles.clear();
    m.paco
      ..x = jefe.centroX - 0.4
      ..y = jefe.y - 0.95
      ..vy = 4;
    for (var i = 0; i < 70 && m.estado == Estado.jugando; i++) {
      m.actualizar(1 / 60);
      if (jefe.invencible > 0.9) break;
    }
  }
}

NivelCreado plano() => NivelCreado.nuevo('t', 'Prueba');

void main() {
  test('3-3: a la izquierda hay un mini jefe; al vencerlo sale el portal al nivel secreto', () {
    final n = todosLosNiveles.firstWhere((n) => n.mundo == 3 && n.numero == 3);
    final m = Motor(n);
    m.enemigos.clear();
    expect(m.jefe, isNotNull);
    expect(m.jefe!.activo, isFalse);
    // Va a la izquierda: la puerta se cierra detrás
    for (var i = 0; i < 60 * 4 && !m.puertaCerrada; i++) {
      m.mandos.izquierda = true;
      m.actualizar(1 / 60);
    }
    m.mandos.izquierda = false;
    expect(m.puertaCerrada, isTrue);
    expect(m.jefe!.activo, isTrue);
    vencerJefe(m);
    expect(m.miniVencido, isTrue);
    expect(m.puertaCerrada, isFalse);
    expect(m.estado, Estado.jugando, reason: 'vencer al mini jefe no termina el nivel');
    // Entra en el portal
    m.paco
      ..x = 3
      ..y = m.mapa.sueloArena - 1;
    for (var i = 0; i < 60 * 3 && m.estado == Estado.jugando; i++) {
      m.vidas = 3;
      m.invencible = 1;
      m.mandos.izquierda = true;
      m.actualizar(1 / 60);
    }
    expect(m.secretoEncontrado, isTrue);
  });

  test('3-3: la meta normal sigue funcionando con el mini jefe', () {
    final n = todosLosNiveles.firstWhere((n) => n.mundo == 3 && n.numero == 3);
    final m = Motor(n);
    m.enemigos.clear();
    m.paco
      ..x = m.mapa.metaX - 2
      ..y = m.mapa.suelo(m.mapa.metaX.floor()) - 1.0;
    for (var i = 0; i < 120; i++) {
      m.mandos.derecha = true;
      m.actualizar(1 / 60);
    }
    expect(m.estado, Estado.ganado);
    expect(m.secretoEncontrado, isFalse);
  });

  test('En el nivel secreto, al perder se vuelve al 3-3', () {
    final m = Motor(nivelArcoiris);
    m.paco.y = 30;
    for (var i = 0; i < 60 * 3; i++) {
      m.actualizar(1 / 60);
    }
    expect(m.volver, isTrue);
  });

  test('Los perros gigantes lanzan bombas y espinas más grandes', () {
    final c = plano();
    c.enemigos.add(const Aparicion(TipoEnemigo.robot, 12, 12, gigante: true));
    final m = Motor(c.nivel, crearMapa: c.mapa);
    final e = m.enemigos.single;
    expect(e.tamano, greaterThan(1.5));
    var bomba = 0.0, espina = 0.0;
    for (var i = 0; i < 60 * 8; i++) {
      m.invencible = 10;
      m.actualizar(1 / 60);
      for (final p in m.proyectiles) {
        if (p.tipo == TipoProyectil.bomba) bomba = p.w;
        if (p.tipo == TipoProyectil.espina) espina = p.w;
      }
    }
    expect(bomba, greaterThan(0.9));
    expect(espina, greaterThan(0.6));
  });

  test('Un jefe puesto en el creador pelea y al vencerlo se gana', () {
    final c = plano()..cambiarAncho(60);
    c.jefe = 'Perro Guardián';
    c.jefeX = 40;
    c.jefeY = 11;
    final json = NivelCreado.fromJson(c.toJson());
    expect(json.jefe, 'Perro Guardián');
    final m = Motor(json.nivel, crearMapa: json.mapa);
    expect(m.jefe, isNotNull);
    m.paco
      ..x = 34
      ..y = 11;
    for (var i = 0; i < 30; i++) {
      m.actualizar(1 / 60);
    }
    expect(m.puertaCerrada, isTrue);
    vencerJefe(m);
    expect(m.estado, Estado.ganado);
  });

  test('Portales, velocidad, fondo, música y agua del creador', () {
    final c = plano();
    c.casillas[5][11] = Casilla.portalAzul;
    c.casillas[50][11] = Casilla.portalAzul;
    c.disparadores.addAll(const [
      Disparador(TipoDisparador.velocidad, 55, 'rapido'),
      Disparador(TipoDisparador.fondo, 56, 'nieve'),
      Disparador(TipoDisparador.musica, 57, 'lava'),
      Disparador(TipoDisparador.agua, 58, '7'),
    ]);
    final copia = NivelCreado.fromJson(c.toJson());
    expect(copia.disparadores, hasLength(4));
    final m = Motor(copia.nivel, crearMapa: copia.mapa);
    expect(m.enAgua, isFalse);
    for (var i = 0; i < 60 && m.paco.x < 40; i++) {
      m.mandos.derecha = true;
      m.actualizar(1 / 60);
    }
    expect(m.paco.x, greaterThan(49), reason: 'el portal lleva al otro portal azul');
    for (var i = 0; i < 60 * 4 && m.paco.x < 62; i++) {
      m.mandos.derecha = true;
      m.actualizar(1 / 60);
    }
    expect(m.velocidad, 1.5);
    expect(m.tema, Temas.nieve);
    expect(m.musica, 'lava');
    for (var i = 0; i < 60 * 4; i++) {
      m.mandos.derecha = false;
      m.actualizar(1 / 60);
    }
    expect(m.nivelAgua, 7);
    expect(m.enAgua, isTrue);
  });

  test('El coral es sólido y los perros gigantes se guardan', () {
    expect(esSolida(Casilla.coral), isTrue);
    final c = plano();
    c.casillas[10][11] = Casilla.coral;
    c.enemigos.add(const Aparicion(TipoEnemigo.perro, 20, 12, gigante: true));
    final copia = NivelCreado.fromJson(c.toJson());
    expect(copia.casillas[10][11], Casilla.coral);
    expect(copia.enemigos.single.gigante, isTrue);
  });
}
