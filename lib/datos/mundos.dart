import 'package:flutter/material.dart';

/// Forma general de un nivel.
enum TipoNivel { suelo, cielo, fortaleza, agua }

/// Adornos que se dibujan al fondo.
enum Decorado {
  colinas,
  nubes,
  arboles,
  muros,
  dunas,
  palmeras,
  corales,
  montanasNieve,
  edificios,
  volcanes,
  burbujas,
  arbolesSecos,
}

/// Colores y adornos de un ambiente.
class Tema {
  final String nombre;
  final Color cieloArriba;
  final Color cieloAbajo;
  final Color tierra;
  final Color cesped;
  final Color ladrillo;

  /// Líquido que llena los huecos. Si es null, los huecos no tienen fondo.
  final Color? liquido;
  final Decorado decorado;

  const Tema({
    required this.nombre,
    required this.cieloArriba,
    required this.cieloAbajo,
    required this.tierra,
    required this.cesped,
    required this.ladrillo,
    this.liquido,
    required this.decorado,
  });
}

class Temas {
  static const planicie = Tema(
    nombre: 'Planicie',
    cieloArriba: Color(0xFF6EC6FF),
    cieloAbajo: Color(0xFFD6F0FF),
    tierra: Color(0xFF9B6B3D),
    cesped: Color(0xFF5DBB3F),
    ladrillo: Color(0xFFC7783A),
    decorado: Decorado.colinas,
  );
  static const cielo = Tema(
    nombre: 'Cielo',
    cieloArriba: Color(0xFF4FA8F0),
    cieloAbajo: Color(0xFFFFE6F2),
    tierra: Color(0xFFF2F6FF),
    cesped: Color(0xFFFFFFFF),
    ladrillo: Color(0xFFFFD27A),
    decorado: Decorado.nubes,
  );
  static const bosque = Tema(
    nombre: 'Bosque',
    cieloArriba: Color(0xFF7CC9A0),
    cieloAbajo: Color(0xFFE2F5D8),
    tierra: Color(0xFF6B4A2B),
    cesped: Color(0xFF2E8B45),
    ladrillo: Color(0xFF8C5A2F),
    decorado: Decorado.arboles,
  );
  static const castillo = Tema(
    nombre: 'Castillo',
    cieloArriba: Color(0xFF2A2338),
    cieloAbajo: Color(0xFF4A3C5C),
    tierra: Color(0xFF6E6A7C),
    cesped: Color(0xFF8D899B),
    ladrillo: Color(0xFF7D6F8F),
    liquido: Color(0xFFFF5A1F),
    decorado: Decorado.muros,
  );
  static const desierto = Tema(
    nombre: 'Desierto',
    cieloArriba: Color(0xFFFFB45C),
    cieloAbajo: Color(0xFFFFEBC2),
    tierra: Color(0xFFD9A55B),
    cesped: Color(0xFFF0CC7A),
    ladrillo: Color(0xFFC08B45),
    decorado: Decorado.dunas,
  );
  static const piramide = Tema(
    nombre: 'Pirámide',
    cieloArriba: Color(0xFF3B2A17),
    cieloAbajo: Color(0xFF6B4D28),
    tierra: Color(0xFFB98A47),
    cesped: Color(0xFFD9AE62),
    ladrillo: Color(0xFFA77935),
    liquido: Color(0xFFE5C07B),
    decorado: Decorado.muros,
  );
  static const playa = Tema(
    nombre: 'Playa',
    cieloArriba: Color(0xFF39B4F2),
    cieloAbajo: Color(0xFFBFF0FF),
    tierra: Color(0xFFE8C88A),
    cesped: Color(0xFFF7E3B0),
    ladrillo: Color(0xFFD69A5A),
    liquido: Color(0xFF2A9FD6),
    decorado: Decorado.palmeras,
  );
  static const barco = Tema(
    nombre: 'Barco',
    cieloArriba: Color(0xFF2F8FD9),
    cieloAbajo: Color(0xFFA9E2FF),
    tierra: Color(0xFF7A4A24),
    cesped: Color(0xFFA0683A),
    ladrillo: Color(0xFF8A5530),
    liquido: Color(0xFF1F7BB8),
    decorado: Decorado.nubes,
  );
  static const marino = Tema(
    nombre: 'Bajo el agua',
    cieloArriba: Color(0xFF1C6FB0),
    cieloAbajo: Color(0xFF0B3966),
    tierra: Color(0xFFD9B97A),
    cesped: Color(0xFFEBD49A),
    ladrillo: Color(0xFFE0707A),
    decorado: Decorado.corales,
  );
  static const submarino = Tema(
    nombre: 'Submarino',
    cieloArriba: Color(0xFF0E4A78),
    cieloAbajo: Color(0xFF06223F),
    tierra: Color(0xFF55606B),
    cesped: Color(0xFF7C8894),
    ladrillo: Color(0xFFF2B33D),
    decorado: Decorado.burbujas,
  );
  static const castilloCielo = Tema(
    nombre: 'Castillo en el cielo',
    cieloArriba: Color(0xFF8E7CF0),
    cieloAbajo: Color(0xFFFFD6E8),
    tierra: Color(0xFFDCD6F2),
    cesped: Color(0xFFF7F3FF),
    ladrillo: Color(0xFFB7A6E8),
    decorado: Decorado.nubes,
  );
  static const nieve = Tema(
    nombre: 'Nieve',
    cieloArriba: Color(0xFF9CC9F0),
    cieloAbajo: Color(0xFFF0F8FF),
    tierra: Color(0xFF9AB6CF),
    cesped: Color(0xFFFFFFFF),
    ladrillo: Color(0xFF7FB8E0),
    decorado: Decorado.montanasNieve,
  );
  static const iglu = Tema(
    nombre: 'Iglú',
    cieloArriba: Color(0xFF3A6E9E),
    cieloAbajo: Color(0xFF7FAED6),
    tierra: Color(0xFFBFDDF2),
    cesped: Color(0xFFF2FAFF),
    ladrillo: Color(0xFF9FCBEA),
    liquido: Color(0xFF3D86C2),
    decorado: Decorado.muros,
  );
  static const ciudad = Tema(
    nombre: 'Ciudad del futuro',
    cieloArriba: Color(0xFF1A1440),
    cieloAbajo: Color(0xFF5B3FA8),
    tierra: Color(0xFF3B3F5C),
    cesped: Color(0xFF34E0E0),
    ladrillo: Color(0xFF6A5AE0),
    decorado: Decorado.edificios,
  );
  static const fabrica = Tema(
    nombre: 'Fábrica de robots',
    cieloArriba: Color(0xFF15182B),
    cieloAbajo: Color(0xFF2E3557),
    tierra: Color(0xFF4A5070),
    cesped: Color(0xFF8BE04E),
    ladrillo: Color(0xFF5C6690),
    liquido: Color(0xFF9DF542),
    decorado: Decorado.edificios,
  );
  static const lava = Tema(
    nombre: 'Lava',
    cieloArriba: Color(0xFF3A0F0F),
    cieloAbajo: Color(0xFFB0391B),
    tierra: Color(0xFF3D2A26),
    cesped: Color(0xFF6B4038),
    ladrillo: Color(0xFF5A3A33),
    liquido: Color(0xFFFF6A1A),
    decorado: Decorado.volcanes,
  );
  static const volcan = Tema(
    nombre: 'Volcán',
    cieloArriba: Color(0xFF240A0A),
    cieloAbajo: Color(0xFF8A2410),
    tierra: Color(0xFF2E211F),
    cesped: Color(0xFF55302A),
    ladrillo: Color(0xFF4A2E29),
    liquido: Color(0xFFFF7F11),
    decorado: Decorado.volcanes,
  );
  static const fortalezaLava = Tema(
    nombre: 'Fortaleza de lava',
    cieloArriba: Color(0xFF1C0A0A),
    cieloAbajo: Color(0xFF4A1610),
    tierra: Color(0xFF4F3B3B),
    cesped: Color(0xFF6E5555),
    ladrillo: Color(0xFF7A3B30),
    liquido: Color(0xFFFF5A1F),
    decorado: Decorado.muros,
  );
  static const veneno = Tema(
    nombre: 'Océano envenenado',
    cieloArriba: Color(0xFF3B4A2A),
    cieloAbajo: Color(0xFF9DB56A),
    tierra: Color(0xFF4F4A3A),
    cesped: Color(0xFF6E8A3C),
    ladrillo: Color(0xFF6B6550),
    liquido: Color(0xFF8BE03A),
    decorado: Decorado.burbujas,
  );
  static const laboratorio = Tema(
    nombre: 'Laboratorio tóxico',
    cieloArriba: Color(0xFF16261A),
    cieloAbajo: Color(0xFF2D4A30),
    tierra: Color(0xFF52605A),
    cesped: Color(0xFF9AA8A0),
    ladrillo: Color(0xFF3F6B4A),
    liquido: Color(0xFFA6F23A),
    decorado: Decorado.muros,
  );
  static const torre = Tema(
    nombre: 'Torre de prueba',
    cieloArriba: Color(0xFF1E1E2E),
    cieloAbajo: Color(0xFF6B4FA0),
    tierra: Color(0xFF5E5A7A),
    cesped: Color(0xFFF2B33D),
    ladrillo: Color(0xFF8C6FD0),
    liquido: Color(0xFFFF5A1F),
    decorado: Decorado.muros,
  );
  static const abandonado = Tema(
    nombre: 'Bosque abandonado',
    cieloArriba: Color(0xFF2E2A3A),
    cieloAbajo: Color(0xFF7A7690),
    tierra: Color(0xFF3E362C),
    cesped: Color(0xFF55604A),
    ladrillo: Color(0xFF5A4A3A),
    decorado: Decorado.arbolesSecos,
  );
  static const castilloFinal = Tema(
    nombre: 'Castillo del Perro Supremo',
    cieloArriba: Color(0xFF120A1A),
    cieloAbajo: Color(0xFF3A1A3A),
    tierra: Color(0xFF3F3550),
    cesped: Color(0xFF6A5A80),
    ladrillo: Color(0xFF5A3A6A),
    liquido: Color(0xFFB13AFF),
    decorado: Decorado.muros,
  );
}

class Jefe {
  final String nombre;
  final int vidas;
  final Color color;

  /// El Perro Supremo lanza huesos.
  final bool lanzaHuesos;
  final bool corona;

  const Jefe(this.nombre, this.vidas, this.color,
      {this.lanzaHuesos = false, this.corona = false});
}

class Nivel {
  final int mundo; // 1..10
  final int numero; // 1..8
  final TipoNivel tipo;
  final Tema tema;
  final Jefe? jefe;

  /// Bolas de fuego que saltan de la lava.
  final bool fuego;

  const Nivel(this.mundo, this.numero, this.tipo, this.tema,
      {this.jefe, this.fuego = false});

  int get indice => (mundo - 1) * 8 + (numero - 1);

  /// Dificultad de 0 (fácil) a ~10 (muy difícil).
  double get dificultad => (mundo - 1) + (numero - 1) / 8;

  String get titulo => '$mundo-$numero  ${tema.nombre}';
}

class Mundo {
  final int numero;
  final String nombre;
  final String descripcion;
  final Color color;
  final List<Nivel> _niveles;
  const Mundo(
      this.numero, this.nombre, this.descripcion, this.color, this._niveles);

  /// Los 8 niveles ordenados del 1 al 8.
  List<Nivel> get niveles =>
      [..._niveles]..sort((a, b) => a.numero - b.numero);
}

const _s = TipoNivel.suelo;
const _c = TipoNivel.cielo;
const _f = TipoNivel.fortaleza;
const _a = TipoNivel.agua;

final List<Mundo> mundos = [
  Mundo(1, 'Las planicies', 'Planicies, cielo, bosque y castillos.',
      const Color(0xFF5DBB3F), [
    const Nivel(1, 1, _s, Temas.planicie),
    const Nivel(1, 2, _c, Temas.cielo),
    const Nivel(1, 3, _s, Temas.planicie),
    const Nivel(1, 4, _f, Temas.castillo,
        jefe: Jefe('Perro Guardián', 3, Color(0xFF8A6A4F))),
    const Nivel(1, 5, _c, Temas.cielo),
    const Nivel(1, 6, _c, Temas.cielo),
    const Nivel(1, 7, _s, Temas.bosque),
    const Nivel(1, 8, _f, Temas.castillo,
        jefe: Jefe('Perro Caballero', 4, Color(0xFF6F6F80)), fuego: true),
  ]),
  Mundo(2, 'El desierto', 'Arena, cactus y pirámides.',
      const Color(0xFFE0A84A), [
    for (final n in [1, 2, 3, 5, 6, 7]) Nivel(2, n, _s, Temas.desierto),
    const Nivel(2, 4, _f, Temas.piramide,
        jefe: Jefe('Perro Momia', 3, Color(0xFFE8E0C8))),
    const Nivel(2, 8, _f, Temas.piramide,
        jefe: Jefe('Perro Faraón', 4, Color(0xFFD9A93A))),
  ]),
  Mundo(3, 'La playa', 'Playa arriba y mar abajo.', const Color(0xFF2A9FD6), [
    for (final n in [1, 2, 3]) Nivel(3, n, _s, Temas.playa),
    const Nivel(3, 4, _f, Temas.barco,
        jefe: Jefe('Perro Pirata', 3, Color(0xFF9A5A3A))),
    for (final n in [5, 6, 7]) Nivel(3, n, _a, Temas.marino),
    const Nivel(3, 8, _a, Temas.submarino,
        jefe: Jefe('Perro Buzo', 4, Color(0xFFF2B33D))),
  ]),
  Mundo(4, 'El cielo', 'Todo flota entre las nubes.', const Color(0xFF7CC7F2), [
    for (final n in [1, 2, 3, 5, 6, 7]) Nivel(4, n, _c, Temas.cielo),
    const Nivel(4, 4, _f, Temas.castilloCielo,
        jefe: Jefe('Perro Nube', 4, Color(0xFFEDEBFF))),
    const Nivel(4, 8, _f, Temas.castilloCielo,
        jefe: Jefe('Perro Trueno', 5, Color(0xFF6B5ED6))),
  ]),
  Mundo(5, 'La nieve', 'Hielo, montañas e iglús.', const Color(0xFFA9D3EE), [
    for (final n in [1, 2, 3, 5, 6, 7]) Nivel(5, n, _s, Temas.nieve),
    const Nivel(5, 4, _f, Temas.iglu,
        jefe: Jefe('Perro Esquimal', 4, Color(0xFFF2F2F2))),
    const Nivel(5, 8, _f, Temas.iglu,
        jefe: Jefe('Perro de las Nieves', 5, Color(0xFFBFE3FF))),
  ]),
  Mundo(6, 'Ciudad del futuro', 'Edificios y tecnología.',
      const Color(0xFF8B6CF0), [
    for (final n in [1, 2, 3, 5, 6, 7]) Nivel(6, n, _s, Temas.ciudad),
    const Nivel(6, 4, _f, Temas.fabrica,
        jefe: Jefe('Perro Robot', 4, Color(0xFFB0B8C8))),
    const Nivel(6, 8, _f, Temas.fabrica,
        jefe: Jefe('Mega Perro Robot', 5, Color(0xFF7A86A0))),
  ]),
  Mundo(7, 'Mundo de lava', 'Lava y volcanes.', const Color(0xFFE2542F), [
    Nivel(7, 1, _s, Temas.lava),
    Nivel(7, 2, _s, Temas.lava),
    Nivel(7, 3, _s, Temas.volcan, fuego: true),
    const Nivel(7, 4, _f, Temas.fortalezaLava,
        jefe: Jefe('Perro de Fuego', 4, Color(0xFFFF7A2A)), fuego: true),
    Nivel(7, 5, _s, Temas.lava),
    Nivel(7, 6, _s, Temas.volcan, fuego: true),
    Nivel(7, 7, _s, Temas.lava, fuego: true),
    const Nivel(7, 8, _f, Temas.fortalezaLava,
        jefe: Jefe('Perro Volcán', 5, Color(0xFFC0301A)), fuego: true),
  ]),
  Mundo(8, 'Océano envenenado', 'Cuidado con el agua verde.',
      const Color(0xFF7BB64A), [
    for (final n in [1, 2, 3, 5, 6, 7]) Nivel(8, n, _s, Temas.veneno),
    const Nivel(8, 4, _f, Temas.laboratorio,
        jefe: Jefe('Perro Tóxico', 5, Color(0xFF9AE04A))),
    const Nivel(8, 8, _f, Temas.laboratorio,
        jefe: Jefe('Perro Mutante', 6, Color(0xFF5FB03A))),
  ]),
  Mundo(9, 'Mundo de prueba', 'Demuestra todo lo que sabes.',
      const Color(0xFFF2A33A), [
    Nivel(9, 1, _s, Temas.planicie),
    Nivel(9, 2, _s, Temas.desierto),
    Nivel(9, 3, _a, Temas.marino),
    const Nivel(9, 4, _f, Temas.torre,
        jefe: Jefe('Perro Maestro', 5, Color(0xFF8C6FD0)), fuego: true),
    Nivel(9, 5, _c, Temas.cielo),
    Nivel(9, 6, _s, Temas.nieve),
    Nivel(9, 7, _s, Temas.volcan, fuego: true),
    const Nivel(9, 8, _f, Temas.torre,
        jefe: Jefe('Gran Perro Maestro', 6, Color(0xFF5A3FA0)), fuego: true),
  ]),
  Mundo(10, 'Bosque abandonado', 'Al final espera el Perro Supremo.',
      const Color(0xFF56604F), [
    for (final n in [1, 2, 3, 4, 5, 6, 7]) Nivel(10, n, _s, Temas.abandonado),
    const Nivel(10, 8, _f, Temas.castilloFinal,
        jefe: Jefe('El Perro Supremo', 8, Color(0xFF8A6A4F),
            lanzaHuesos: true, corona: true),
        fuego: true),
  ]),
];

/// Los 80 niveles en orden.
final List<Nivel> todosLosNiveles = [
  for (final m in mundos) ...m.niveles
];
