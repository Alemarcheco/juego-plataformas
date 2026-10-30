import 'dart:math';

import '../datos/mundos.dart';

/// Casillas del mapa.
enum Casilla {
  vacio,
  tierra,
  ladrillo,
  liquido,
  pinchos,
  moneda,
  corazon,

  /// Parece tierra pero se puede atravesar (camino secreto).
  falso,

  /// Puerta al mundo secreto.
  portal,
}

bool esSolida(Casilla c) => c == Casilla.tierra || c == Casilla.ladrillo;

enum TipoEnemigo {
  perro,
  saltarin,
  volador,
  pez,
  fuego,

  /// Perro que lanza hielo.
  hielo,

  /// Perro que lanza llamas.
  llamas,

  /// Perro que dispara bolas de ácido (quitan toda la vida).
  acido,

  /// Perro de espinas: se infla y explota cuando Paco se acerca.
  espinoso,

  /// Perro robot: lanza una bomba que flota y explota en 8 espinas.
  robot,

  /// Pez globo: se hincha cuando Paco se acerca y explota en 8 espinas.
  pezGlobo,

  /// Pez de hielo: dispara espinas de hielo en horizontal.
  pezHielo,

  /// Pez morado: persigue a Paco.
  pezMorado,
}

class Aparicion {
  final TipoEnemigo tipo;
  final double x;
  final double y;
  const Aparicion(this.tipo, this.x, this.y);
}

/// Un nivel ya construido: casillas, enemigos y meta.
class Mapa {
  static const int alto = 15;
  final int ancho;
  final List<List<Casilla>> casillas; // [x][y], y = 0 arriba
  final List<Aparicion> enemigos = [];
  double inicioX = 2;
  double inicioY = 5;
  double metaX = 0;
  double controlX = 0;

  /// En los niveles del creador las banderas van donde se pusieron
  /// (fila de la casilla donde se apoyan); si no, sobre el suelo.
  int? metaY;
  int? controlY;

  /// Para niveles con jefe: dónde empieza la arena.
  double? arenaX;
  double sueloArena = 0;

  Mapa(this.ancho)
      : casillas =
            List.generate(ancho, (_) => List.filled(alto, Casilla.vacio));

  Casilla en(int x, int y) {
    if (x < 0 || x >= ancho) return Casilla.tierra; // paredes laterales
    if (y < 0) return Casilla.vacio;
    if (y >= alto) return Casilla.vacio;
    return casillas[x][y];
  }

  void poner(int x, int y, Casilla c) {
    if (x < 0 || x >= ancho || y < 0 || y >= alto) return;
    casillas[x][y] = c;
  }

  /// Rellena una columna con tierra desde [desde] hasta abajo.
  void columna(int x, int desde, [Casilla c = Casilla.tierra]) {
    for (var y = desde; y < alto; y++) {
      poner(x, y, c);
    }
  }

  /// Altura del primer bloque sólido de la columna (o alto si no hay).
  int superficie(int x) {
    for (var y = 0; y < alto; y++) {
      if (esSolida(en(x, y))) return y;
    }
    return alto;
  }

  /// Fila del suelo donde se puede estar de pie, saltándose el techo
  /// (en castillos y pirámides la columna empieza con bloques arriba).
  int suelo(int x) {
    var y = 0;
    while (y < alto && esSolida(en(x, y))) {
      y++;
    }
    while (y < alto && !esSolida(en(x, y))) {
      y++;
    }
    return y;
  }
}

/// Construye el mapa de un nivel. Siempre da el mismo mapa para el mismo nivel.
Mapa generarMapa(Nivel nivel) {
  final g = _Generador(nivel);
  switch (nivel.tipo) {
    case TipoNivel.suelo:
      final m = g.suelo();
      return nivel.caminoSecreto ? _conCaminoSecreto(m) : m;
    case TipoNivel.cielo:
      return g.cielo();
    case TipoNivel.fortaleza:
      return g.fortaleza();
    case TipoNivel.agua:
      return g.agua();
  }
}

/// Ancho de la zona secreta escondida a la izquierda del inicio.
const anchoSecreto = 16;

/// Añade a la izquierda del inicio una pared falsa con el portal al mundo secreto.
Mapa _conCaminoSecreto(Mapa original) {
  const extra = anchoSecreto;
  final m = Mapa(original.ancho + extra);
  for (var x = 0; x < original.ancho; x++) {
    for (var y = 0; y < Mapa.alto; y++) {
      m.casillas[x + extra][y] = original.casillas[x][y];
    }
  }
  final suelo = original.superficie(0);
  for (var x = 0; x < extra; x++) {
    m.columna(x, suelo);
    for (var y = 0; y < suelo; y++) {
      m.poner(x, y, Casilla.falso);
    }
  }
  // Pasillo con pescados y el portal al fondo
  for (var x = 3; x < extra - 1; x += 2) {
    m.poner(x, suelo - 1, Casilla.moneda);
  }
  m.poner(1, suelo - 1, Casilla.portal);
  m.poner(1, suelo - 2, Casilla.portal);
  m.inicioX = original.inicioX + extra;
  m.inicioY = original.inicioY;
  m.controlX = original.controlX + extra;
  m.metaX = original.metaX + extra;
  for (final a in original.enemigos) {
    m.enemigos.add(Aparicion(a.tipo, a.x + extra, a.y));
  }
  return m;
}

class _Generador {
  final Nivel nivel;
  final Random r;
  final double d;
  late final Mapa m;

  _Generador(this.nivel)
      : r = Random(nivel.mundo * 1000 + nivel.numero * 37 + 7),
        d = nivel.dificultad;

  int get largo => (160 + d * 12).round();

  /// Hueco más ancho que se puede saltar (Paco salta unas 5 casillas).
  int get huecoMax => min(4, 2 + (d / 3).floor());

  bool azar(double p) => r.nextDouble() < p;
  int entre(int a, int b) => a + r.nextInt(b - a + 1);

  double get probEnemigo => min(0.75, 0.25 + d * 0.05);

  TipoEnemigo enemigoDeSuelo() {
    final w = nivel.mundo;
    final especiales = [
      if (w >= 2 && w != 3) TipoEnemigo.espinoso,
      if (w == 5 || w >= 9) TipoEnemigo.hielo,
      if (w == 6 || w == 7 || w >= 9) TipoEnemigo.llamas,
      if (w == 6 || w == 8 || w >= 9) TipoEnemigo.acido,
      if (w == 6 || w >= 9) TipoEnemigo.robot,
    ];
    if (especiales.isNotEmpty && azar(0.4)) {
      return especiales[r.nextInt(especiales.length)];
    }
    if (d >= 2 && azar(0.25 + d * 0.02)) return TipoEnemigo.saltarin;
    return TipoEnemigo.perro;
  }

  void monedasEnArco(int x0, int x1, int ySuelo) {
    for (var x = x0; x <= x1; x++) {
      final t = (x - x0) / max(1, x1 - x0);
      final y = ySuelo - 2 - (sin(t * pi) * 2).round();
      if (m.en(x, y) == Casilla.vacio) m.poner(x, y, Casilla.moneda);
    }
  }

  void huecoLiquido(int x) {
    final liq = nivel.tema.liquido;
    if (liq != null) {
      m.poner(x, Mapa.alto - 1, Casilla.liquido);
      m.poner(x, Mapa.alto - 2, Casilla.liquido);
    }
  }

  void meta(int desde, int ySuelo) {
    for (var x = desde; x < m.ancho; x++) {
      m.columna(x, ySuelo);
    }
    m.metaX = m.ancho - 6.0;
  }

  // ---------------------------------------------------------------- suelo
  Mapa suelo() {
    m = Mapa(largo);
    var h = 12; // fila de la superficie
    var x = 0;
    for (; x < 8; x++) {
      m.columna(x, h);
    }
    m.inicioX = 2;
    m.inicioY = h - 2.0;
    var corazonPuesto = false;
    while (x < m.ancho - 16) {
      final tirada = r.nextDouble();
      if (tirada < 0.42) {
        // Tramo plano
        final n = entre(4, 9);
        for (var i = 0; i < n; i++) {
          m.columna(x + i, h);
        }
        if (n >= 5 && azar(probEnemigo)) {
          m.enemigos.add(Aparicion(enemigoDeSuelo(), x + n - 2.0, h - 1.0));
        }
        if (n >= 6 && d >= 1 && azar(0.35)) {
          m.poner(x + n ~/ 2, h - 1, Casilla.pinchos);
        }
        if (azar(0.45)) {
          // Plataforma de ladrillos con monedas encima
          final py = h - 4;
          final pw = entre(3, 5);
          final px = x + entre(0, max(0, n - pw));
          for (var i = 0; i < pw; i++) {
            m.poner(px + i, py, Casilla.ladrillo);
            m.poner(px + i, py - 1, Casilla.moneda);
          }
          if (!corazonPuesto && azar(0.2)) {
            m.poner(px, py - 1, Casilla.corazon);
            corazonPuesto = true;
          }
        } else if (azar(0.5)) {
          for (var i = 1; i < n - 1; i++) {
            if (m.en(x + i, h - 1) == Casilla.vacio) {
              m.poner(x + i, h - 1, Casilla.moneda);
            }
          }
        }
        x += n;
      } else if (tirada < 0.70) {
        // Hueco
        final n = entre(2, huecoMax);
        for (var i = 0; i < n; i++) {
          huecoLiquido(x + i);
        }
        monedasEnArco(x - 1, x + n, h);
        if (nivel.fuego && n >= 3 && nivel.tema.liquido != null) {
          m.enemigos.add(
              Aparicion(TipoEnemigo.fuego, x + n / 2 - 0.4, Mapa.alto - 1.0));
        }
        x += n;
        // Siempre se aterriza en un tramo plano
        for (var i = 0; i < 3; i++) {
          m.columna(x + i, h);
        }
        x += 3;
      } else if (tirada < 0.88) {
        // Escalón
        final cambio = azar(0.5) ? -entre(1, 2) : entre(1, 2);
        h = (h + cambio).clamp(7, 13);
        final n = entre(3, 6);
        for (var i = 0; i < n; i++) {
          m.columna(x + i, h);
        }
        x += n;
      } else {
        // Escalera de bloques
        final n = entre(3, 4);
        for (var i = 0; i < n; i++) {
          m.columna(x + i, h);
          for (var k = 1; k <= i; k++) {
            m.poner(x + i, h - k, Casilla.ladrillo);
          }
        }
        x += n;
        for (var i = 0; i < 3; i++) {
          m.columna(x + i, h);
        }
        x += 3;
      }
      if (m.controlX == 0 && x > m.ancho / 2) {
        // Bandera de control en una columna con suelo
        for (var i = 0; i < 3; i++) {
          m.columna(x + i, h);
        }
        m.controlX = x + 1.0;
        x += 3;
      }
    }
    meta(x, h);
    _voladores(4);
    return m;
  }

  /// Añade perros voladores sobre el nivel.
  void _voladores(int cada) {
    if (d < 1.5) return;
    final n = (m.ancho / 40 * min(3, d / 3)).round();
    for (var i = 0; i < n; i++) {
      final x = 20 + r.nextInt(m.ancho - 40);
      final sup = m.superficie(x);
      final y = min(sup, Mapa.alto) - 4.0;
      if (y > 2) m.enemigos.add(Aparicion(TipoEnemigo.volador, x.toDouble(), y));
    }
  }

  // ---------------------------------------------------------------- cielo
  Mapa cielo() {
    m = Mapa(largo);
    var y = 10;
    var x = 0;
    void isla(int ancho, int fila) {
      for (var i = 0; i < ancho; i++) {
        m.poner(x + i, fila, Casilla.tierra);
        if (ancho > 4 || i == 0 || i == ancho - 1) {
          m.poner(x + i, fila + 1, Casilla.tierra);
        }
      }
    }

    isla(8, y);
    m.inicioX = 2;
    m.inicioY = y - 2.0;
    x += 8;
    final huecoCielo = min(4, 2 + (d / 4).floor());
    while (x < m.ancho - 16) {
      final hueco = entre(2, huecoCielo);
      x += hueco;
      final sube = -entre(0, 2);
      final baja = entre(0, 3);
      y = (y + (azar(0.5) ? sube : baja)).clamp(5, 12);
      final ancho = entre(max(3, 6 - (d ~/ 3)), 7);
      isla(ancho, y);
      if (ancho >= 5 && azar(probEnemigo)) {
        m.enemigos.add(Aparicion(enemigoDeSuelo(), x + ancho - 2.0, y - 1.0));
      }
      for (var i = 1; i < ancho - 1; i++) {
        if (azar(0.5)) m.poner(x + i, y - 1, Casilla.moneda);
      }
      if (azar(0.1)) m.poner(x + 1, y - 3, Casilla.corazon);
      if (d >= 1 && hueco >= 3 && azar(0.4)) {
        m.enemigos.add(
            Aparicion(TipoEnemigo.volador, x - hueco / 2, y - 3.0));
      }
      x += ancho;
      if (m.controlX == 0 && x > m.ancho / 2) {
        x += 1;
        isla(5, y);
        m.controlX = x + 2.0;
        x += 5;
      }
    }
    x += 2;
    for (var i = x; i < m.ancho; i++) {
      m.poner(i, y, Casilla.tierra);
      m.poner(i, y + 1, Casilla.tierra);
    }
    m.metaX = m.ancho - 6.0;
    // Mar de veneno (u otro líquido) debajo de las plataformas
    if (nivel.tema.liquido != null) {
      for (var i = 0; i < m.ancho; i++) {
        for (var fila = Mapa.alto - 2; fila < Mapa.alto; fila++) {
          if (m.casillas[i][fila] == Casilla.vacio) {
            m.poner(i, fila, Casilla.liquido);
          }
        }
      }
    }
    return m;
  }

  // ------------------------------------------------------------ fortaleza
  Mapa fortaleza() {
    m = Mapa(largo);
    const h = 12;
    final aire = nivel.tema.liquido == null; // castillo en el cielo
    var x = 0;
    // La plataforma voladora no tiene techo
    final sinTecho = identical(nivel.tema, Temas.plataformaVoladora);
    void techo(int col) {
      if (sinTecho) return;
      m.poner(col, 0, Casilla.ladrillo);
      m.poner(col, 1, Casilla.ladrillo);
    }

    for (; x < 8; x++) {
      m.columna(x, h, Casilla.ladrillo);
      techo(x);
    }
    m.inicioX = 2;
    m.inicioY = h - 2.0;
    final arenaLargo = 22;
    while (x < m.ancho - arenaLargo - 4) {
      final tirada = r.nextDouble();
      if (tirada < 0.4) {
        final n = entre(4, 8);
        for (var i = 0; i < n; i++) {
          m.columna(x + i, h, Casilla.ladrillo);
          techo(x + i);
        }
        if (azar(probEnemigo)) {
          m.enemigos.add(Aparicion(enemigoDeSuelo(), x + n - 2.0, h - 1.0));
        }
        if (n >= 5 && azar(0.5)) {
          m.poner(x + n ~/ 2, h - 1, Casilla.pinchos);
          if (d >= 3 && n >= 7) m.poner(x + n ~/ 2 + 1, h - 1, Casilla.pinchos);
        }
        if (azar(0.4)) {
          for (var i = 1; i < n - 1; i++) {
            m.poner(x + i, h - 4, Casilla.moneda);
          }
        }
        x += n;
      } else if (tirada < 0.72) {
        final n = entre(2, huecoMax);
        for (var i = 0; i < n; i++) {
          if (!aire) {
            m.poner(x + i, Mapa.alto - 1, Casilla.liquido);
            m.poner(x + i, Mapa.alto - 2, Casilla.liquido);
          }
          techo(x + i);
        }
        monedasEnArco(x - 1, x + n, h);
        if (nivel.fuego && n >= 3 && !aire) {
          m.enemigos.add(
              Aparicion(TipoEnemigo.fuego, x + n / 2 - 0.4, Mapa.alto - 1.0));
        }
        x += n;
        for (var i = 0; i < 3; i++) {
          m.columna(x + i, h, Casilla.ladrillo);
          techo(x + i);
        }
        x += 3;
      } else {
        // Columna para saltar por encima
        final alto = entre(1, 2);
        for (var i = 0; i < 4; i++) {
          m.columna(x + i, h, Casilla.ladrillo);
          techo(x + i);
        }
        for (var k = 1; k <= alto; k++) {
          m.poner(x + 1, h - k, Casilla.ladrillo);
          m.poner(x + 2, h - k, Casilla.ladrillo);
        }
        m.poner(x + 1, h - alto - 1, Casilla.moneda);
        m.poner(x + 2, h - alto - 1, Casilla.moneda);
        x += 4;
        for (var i = 0; i < 2; i++) {
          m.columna(x + i, h, Casilla.ladrillo);
          techo(x + i);
        }
        x += 2;
      }
      if (m.controlX == 0 && x > m.ancho / 2) {
        for (var i = 0; i < 3; i++) {
          m.columna(x + i, h, Casilla.ladrillo);
          techo(x + i);
        }
        m.controlX = x + 1.0;
        x += 3;
      }
    }
    // Arena del jefe
    for (var i = x; i < m.ancho; i++) {
      m.columna(i, h, Casilla.ladrillo);
      techo(i);
    }
    m.poner(x + 4, h - 3, Casilla.corazon);
    m.arenaX = x + 2.0;
    m.sueloArena = h.toDouble();
    m.metaX = m.ancho - 3.0;
    return m;
  }

  // ----------------------------------------------------------------- agua
  Mapa agua() {
    m = Mapa(largo);
    var x = 0;
    var piso = 12;
    var techoAlto = 1;
    for (; x < 6; x++) {
      m.columna(x, piso);
      for (var y = 0; y <= techoAlto; y++) {
        m.poner(x, y, Casilla.tierra);
      }
    }
    m.inicioX = 2;
    m.inicioY = 7;
    final conJefe = nivel.jefe != null;
    final fin = conJefe ? m.ancho - 24 : m.ancho - 10;
    while (x < fin) {
      final n = entre(3, 7);
      piso = (piso + entre(-1, 1)).clamp(10, 13);
      techoAlto = (techoAlto + entre(-1, 1)).clamp(0, 3);
      for (var i = 0; i < n; i++) {
        m.columna(x + i, piso);
        for (var y = 0; y <= techoAlto; y++) {
          m.poner(x + i, y, Casilla.tierra);
        }
      }
      // Coral desde el suelo o desde el techo dejando paso
      if (azar(0.45)) {
        final cx = x + n ~/ 2;
        if (azar(0.5)) {
          final alto = entre(2, 4);
          for (var k = 1; k <= alto; k++) {
            m.poner(cx, piso - k, Casilla.ladrillo);
          }
        } else {
          final alto = entre(2, 4);
          for (var k = 1; k <= alto; k++) {
            m.poner(cx, techoAlto + k, Casilla.ladrillo);
          }
        }
      }
      if (azar(probEnemigo)) {
        final tirada = r.nextDouble();
        final pez = tirada < 0.4
            ? TipoEnemigo.pez
            : tirada < 0.6
                ? TipoEnemigo.pezGlobo
                : tirada < 0.8
                    ? TipoEnemigo.pezHielo
                    : TipoEnemigo.pezMorado;
        m.enemigos.add(Aparicion(
            pez, x + n / 2, entre(techoAlto + 3, piso - 2) * 1.0));
      }
      if (d >= 2 && azar(0.25)) {
        m.poner(x + 1, piso - 1, Casilla.pinchos);
      }
      for (var i = 0; i < n; i++) {
        if (azar(0.35)) {
          final y = entre(techoAlto + 2, piso - 2);
          if (m.en(x + i, y) == Casilla.vacio) m.poner(x + i, y, Casilla.moneda);
        }
      }
      if (azar(0.06)) m.poner(x + 1, piso - 3, Casilla.corazon);
      x += n;
      if (m.controlX == 0 && x > m.ancho / 2) m.controlX = x.toDouble();
    }
    piso = 12;
    for (var i = x; i < m.ancho; i++) {
      m.columna(i, piso);
      m.poner(i, 0, Casilla.tierra);
    }
    if (conJefe) {
      m.arenaX = x + 2.0;
      m.sueloArena = piso.toDouble();
      m.metaX = m.ancho - 3.0;
    } else {
      m.metaX = m.ancho - 6.0;
    }
    return m;
  }
}
