import 'dart:math';

import '../datos/mundos.dart';
import 'generador.dart';

/// Algo que se mueve y choca con las casillas.
class Cuerpo {
  double x, y, w, h;
  double vx = 0, vy = 0;
  bool enSuelo = false;
  bool chocoPared = false;
  Cuerpo(this.x, this.y, this.w, this.h);

  double get centroX => x + w / 2;
  double get abajo => y + h;

  bool toca(Cuerpo o) =>
      x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y;
}

class Enemigo extends Cuerpo {
  final TipoEnemigo tipo;
  final double baseX, baseY;
  double t;
  int dir = -1;
  bool vivo = true;
  double aplastado = 0; // tiempo de la animación al morir
  double espera = 0;
  bool activo = false;

  Enemigo(this.tipo, double x, double y, double w, double h, this.t)
      : baseX = x,
        baseY = y,
        super(x, y, w, h);

  bool get pisable => tipo != TipoEnemigo.fuego;
}

class JefeVivo extends Cuerpo {
  final Jefe datos;
  int vidas;
  int dir = -1;
  double invencible = 0;
  double espera = 1.5;
  double lanzar = 2;
  double derrotado = 0;
  bool activo = false;
  JefeVivo(this.datos, double x, double y)
      : vidas = datos.vidas,
        super(x, y, 1.8, 1.6);
}

class Hueso extends Cuerpo {
  double giro = 0;
  Hueso(double x, double y, double vx) : super(x, y, 0.6, 0.35) {
    this.vx = vx;
    vy = -9;
  }
}

/// Teclas o botones que se están pulsando.
class Mandos {
  bool izquierda = false;
  bool derecha = false;
  bool salto = false;
}

enum Estado { jugando, muerto, ganado }

/// Toda la lógica de un nivel en marcha.
class Motor {
  final Nivel nivel;
  late Mapa mapa;
  late Cuerpo paco;
  final List<Enemigo> enemigos = [];
  final List<Hueso> huesos = [];
  JefeVivo? jefe;
  final Mandos mandos = Mandos();

  Estado estado = Estado.jugando;
  int vidas = 3;
  int pescados = 0;
  int totalPescados = 0;
  double t = 0;
  double invencible = 0;
  double tiempoMuerto = 0;
  double tiempoGanado = 0;
  bool control = false;
  bool puertaCerrada = false;
  int dirPaco = 1;
  double pasos = 0;

  double camX = 0;
  double anchoVista = 26;

  // Ayudas para que el salto se sienta bien
  double _coyote = 0;
  double _bufferSalto = 0;
  bool _saltoAntes = false;

  bool get enAgua => nivel.tipo == TipoNivel.agua;

  Motor(this.nivel) {
    mapa = generarMapa(nivel);
    for (final col in mapa.casillas) {
      for (final c in col) {
        if (c == Casilla.moneda) totalPescados++;
      }
    }
    _colocarPaco();
    _crearEnemigos();
  }

  void _colocarPaco() {
    final x = control ? mapa.controlX : mapa.inicioX;
    final y = control ? mapa.superficie(mapa.controlX.floor()) - 1.0 : mapa.inicioY;
    paco = Cuerpo(x, enAgua && !control ? mapa.inicioY : y, 0.8, 0.9);
    dirPaco = 1;
    camX = max(0, paco.x - anchoVista * 0.35);
  }

  void _crearEnemigos() {
    enemigos.clear();
    huesos.clear();
    final rnd = Random(nivel.indice);
    for (final a in mapa.enemigos) {
      final fase = rnd.nextDouble() * 6;
      switch (a.tipo) {
        case TipoEnemigo.perro:
        case TipoEnemigo.saltarin:
          enemigos.add(Enemigo(a.tipo, a.x, a.y - 0.8, 0.95, 0.8, fase));
        case TipoEnemigo.volador:
          enemigos.add(Enemigo(a.tipo, a.x, a.y, 0.9, 0.7, fase));
        case TipoEnemigo.pez:
          enemigos.add(Enemigo(a.tipo, a.x, a.y, 0.95, 0.65, fase));
        case TipoEnemigo.fuego:
          enemigos.add(Enemigo(a.tipo, a.x, a.y, 0.75, 0.75, fase));
      }
    }
    final datos = nivel.jefe;
    if (datos != null && mapa.arenaX != null) {
      jefe = JefeVivo(datos, mapa.ancho - 6.0, mapa.sueloArena - 1.6);
    }
  }

  double get dificultad => nivel.dificultad;

  // --------------------------------------------------------------- física
  bool _solida(int x, int y) => esSolida(mapa.en(x, y));

  void mover(Cuerpo c, double dt) {
    c.chocoPared = false;
    c.x += c.vx * dt;
    final arriba = c.y.floor();
    final abajo = (c.y + c.h - 0.001).floor();
    if (c.vx > 0) {
      final col = (c.x + c.w).floor();
      for (var y = arriba; y <= abajo; y++) {
        if (_solida(col, y)) {
          c.x = col - c.w;
          c.chocoPared = true;
          break;
        }
      }
    } else if (c.vx < 0) {
      final col = c.x.floor();
      for (var y = arriba; y <= abajo; y++) {
        if (_solida(col, y)) {
          c.x = col + 1.0;
          c.chocoPared = true;
          break;
        }
      }
    }
    c.y += c.vy * dt;
    c.enSuelo = false;
    final izq = c.x.floor();
    final der = (c.x + c.w - 0.001).floor();
    if (c.vy > 0) {
      final fila = (c.y + c.h).floor();
      for (var x = izq; x <= der; x++) {
        if (_solida(x, fila)) {
          c.y = fila - c.h;
          c.vy = 0;
          c.enSuelo = true;
          break;
        }
      }
    } else if (c.vy < 0) {
      final fila = c.y.floor();
      for (var x = izq; x <= der; x++) {
        if (_solida(x, fila)) {
          c.y = fila + 1.0;
          c.vy = 0;
          break;
        }
      }
    }
  }

  // ----------------------------------------------------------- actualizar
  void actualizar(double dt) {
    dt = min(dt, 1 / 30);
    const pasos = 2;
    for (var i = 0; i < pasos; i++) {
      _paso(dt / pasos);
    }
  }

  void _paso(double dt) {
    t += dt;
    switch (estado) {
      case Estado.muerto:
        tiempoMuerto += dt;
        paco.vy += 30 * dt;
        paco.y += paco.vy * dt;
        if (tiempoMuerto > 1.6) _reaparecer();
        return;
      case Estado.ganado:
        tiempoGanado += dt;
        if (!enAgua) {
          paco.vy += 40 * dt;
          paco.vx = 0;
          mover(paco, dt);
        }
        _actualizarJefe(dt);
        return;
      case Estado.jugando:
        break;
    }
    _actualizarPaco(dt);
    _actualizarEnemigos(dt);
    _actualizarJefe(dt);
    _actualizarHuesos(dt);
    _camara();
  }

  void _actualizarPaco(double dt) {
    final p = paco;
    final agua = enAgua;
    final velMax = agua ? 4.5 : 7.5;
    final acel = agua ? 18.0 : 45.0;
    var quiere = 0;
    if (mandos.izquierda) quiere -= 1;
    if (mandos.derecha) quiere += 1;
    if (quiere != 0) {
      dirPaco = quiere;
      p.vx += quiere * acel * dt;
      p.vx = p.vx.clamp(-velMax, velMax);
    } else {
      final freno = (agua ? 8.0 : 35.0) * dt;
      if (p.vx.abs() <= freno) {
        p.vx = 0;
      } else {
        p.vx -= p.vx.sign * freno;
      }
    }

    final pulsado = mandos.salto && !_saltoAntes;
    _saltoAntes = mandos.salto;
    if (pulsado) _bufferSalto = 0.13;
    _bufferSalto -= dt;

    if (agua) {
      p.vy += 11 * dt;
      if (p.vy > 3.5) p.vy = 3.5;
      if (pulsado) p.vy = -6.8;
    } else {
      if (p.enSuelo) _coyote = 0.1;
      _coyote -= dt;
      if (_bufferSalto > 0 && _coyote > 0) {
        p.vy = -16.5;
        _bufferSalto = 0;
        _coyote = 0;
      }
      if (!mandos.salto && p.vy < -6) p.vy = -6;
      p.vy += 42 * dt;
      if (p.vy > 18) p.vy = 18;
    }
    mover(p, dt);
    if (p.enSuelo && p.vx != 0) pasos += p.vx.abs() * dt;
    if (p.y < -2 && agua) p.y = -2;

    if (invencible > 0) invencible -= dt;

    // Casillas que toca
    final x0 = p.x.floor(), x1 = (p.x + p.w - 0.001).floor();
    final y0 = p.y.floor(), y1 = (p.y + p.h - 0.001).floor();
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        final c = mapa.en(x, y);
        switch (c) {
          case Casilla.moneda:
            mapa.poner(x, y, Casilla.vacio);
            pescados++;
          case Casilla.corazon:
            mapa.poner(x, y, Casilla.vacio);
            vidas = min(5, vidas + 1);
          case Casilla.liquido:
            if (p.y + p.h > y + 0.3) _morir();
          case Casilla.pinchos:
            if (p.y + p.h > y + 0.45) _herir(desdeX: x + 0.5);
          default:
            break;
        }
      }
    }
    if (p.y > Mapa.alto + 1) _morir();

    if (!control && mapa.controlX > 0 && p.x >= mapa.controlX) control = true;

    // Meta
    if (jefe == null && p.x + p.w >= mapa.metaX) {
      _ganar();
    }
    // Arena del jefe
    final arena = mapa.arenaX;
    if (arena != null && !puertaCerrada && p.x > arena + 1.5) {
      puertaCerrada = true;
      final col = arena.floor() - 1;
      for (var y = 0; y < mapa.sueloArena; y++) {
        mapa.poner(col, y, Casilla.ladrillo);
      }
      jefe?.activo = true;
    }
  }

  void _actualizarEnemigos(double dt) {
    final p = paco;
    final vel = min(3.6, 1.8 + dificultad * 0.17);
    for (final e in enemigos) {
      if (!e.vivo) {
        e.aplastado += dt;
        continue;
      }
      if (!e.activo) {
        if ((e.x - p.x).abs() < anchoVista * 0.75) e.activo = true;
        continue;
      }
      e.t += dt;
      switch (e.tipo) {
        case TipoEnemigo.perro:
        case TipoEnemigo.saltarin:
          e.vx = e.dir * vel;
          e.vy += (enAgua ? 11 : 40) * dt;
          if (e.vy > 18) e.vy = 18;
          if (e.tipo == TipoEnemigo.saltarin && e.enSuelo) {
            e.espera -= dt;
            if (e.espera <= 0) {
              e.vy = -12;
              e.espera = 1.2 + (e.t % 1.0);
            }
          }
          mover(e, dt);
          if (e.chocoPared) e.dir = -e.dir;
          if (e.enSuelo) {
            final pieX = e.dir > 0 ? (e.x + e.w + 0.05) : (e.x - 0.05);
            if (!_solida(pieX.floor(), (e.y + e.h + 0.1).floor())) {
              e.dir = -e.dir;
            }
          }
          if (e.y > Mapa.alto + 1) e.vivo = false;
        case TipoEnemigo.volador:
          final nx = e.baseX + sin(e.t * 0.8) * 3;
          e.dir = nx >= e.x ? 1 : -1;
          e.x = nx;
          e.y = e.baseY + sin(e.t * 2.2) * 0.9;
        case TipoEnemigo.pez:
          final nx = e.baseX + sin(e.t * 0.6) * 3;
          e.dir = nx >= e.x ? 1 : -1;
          e.x = nx;
          e.y = e.baseY + sin(e.t * 1.5) * 0.6;
        case TipoEnemigo.fuego:
          const periodo = 2.8;
          final fase = (e.t % periodo) / periodo;
          if (fase < 0.6) {
            final s = sin(fase / 0.6 * pi);
            e.y = e.baseY - s * 7;
            e.dir = fase < 0.3 ? -1 : 1;
          } else {
            e.y = e.baseY + 2;
          }
      }
      _contacto(e);
    }
  }

  /// Paco toca a un enemigo: o lo pisa o se hace daño.
  void _contacto(Cuerpo e) {
    final p = paco;
    if (!p.toca(e)) return;
    final pisable = e is Enemigo ? e.pisable : true;
    final pisa = pisable && p.vy > 0 && (p.abajo - e.y) < 0.55;
    if (pisa) {
      p.vy = mandos.salto ? -15 : -10;
      if (e is Enemigo) {
        e.vivo = false;
      } else if (e is JefeVivo) {
        _golpearJefe(e);
      }
    } else {
      if (e is JefeVivo && e.invencible > 0) return;
      _herir(desdeX: e.x + e.w / 2);
    }
  }

  void _golpearJefe(JefeVivo j) {
    if (j.invencible > 0) return;
    j.vidas--;
    j.invencible = 1.0;
    if (j.vidas <= 0) {
      j.derrotado = 0.001;
      _ganar();
    }
  }

  void _actualizarJefe(double dt) {
    final j = jefe;
    if (j == null) return;
    if (j.derrotado > 0) {
      j.derrotado += dt;
      j.vy += 20 * dt;
      j.y += j.vy * dt;
      return;
    }
    if (!j.activo) return;
    if (j.invencible > 0) j.invencible -= dt;
    final furia = 1 - j.vidas / j.datos.vidas; // 0 al principio, ~1 al final
    final vel = 1.8 + dificultad * 0.1 + furia * 1.2;
    final arena = mapa.arenaX ?? 0;
    if (j.x < arena + 1) j.dir = 1;
    if (j.x > mapa.ancho - 3) j.dir = -1;
    j.vx = j.dir * vel;
    final g = enAgua ? 14.0 : 40.0;
    j.vy += g * dt;
    if (j.vy > 18) j.vy = 18;
    if (j.enSuelo) {
      j.espera -= dt;
      if (j.espera <= 0) {
        j.vy = enAgua ? -9 : -13;
        j.espera = 1.2 + (1 - furia) * 1.3;
        // Mira hacia Paco al saltar
        j.dir = paco.centroX > j.centroX ? 1 : -1;
      }
    }
    mover(j, dt);
    if (j.chocoPared) j.dir = -j.dir;
    if (j.datos.lanzaHuesos) {
      j.lanzar -= dt;
      if (j.lanzar <= 0) {
        j.lanzar = 2.2 - furia;
        final hacia = paco.centroX > j.centroX ? 1.0 : -1.0;
        huesos.add(Hueso(j.centroX, j.y + 0.3, hacia * 6.5));
      }
    }
    if (estado == Estado.jugando) _contacto(j);
  }

  void _actualizarHuesos(double dt) {
    for (final h in huesos) {
      h.vy += 20 * dt;
      h.x += h.vx * dt;
      h.y += h.vy * dt;
      h.giro += dt * 10;
      if (h.toca(paco)) {
        _herir(desdeX: h.x);
        h.y = 99;
      }
    }
    huesos.removeWhere((h) => h.y > Mapa.alto + 2);
  }

  void _camara() {
    final objetivo = paco.x - anchoVista * 0.38;
    camX += (objetivo - camX) * 0.18;
    camX = camX.clamp(0, max(0.0, mapa.ancho - anchoVista));
    final arena = mapa.arenaX;
    if (puertaCerrada && arena != null) {
      camX = max(camX, min(arena - 1, mapa.ancho - anchoVista));
    }
  }

  // --------------------------------------------------------------- sucesos
  void _herir({required double desdeX}) {
    if (invencible > 0 || estado != Estado.jugando) return;
    vidas--;
    if (vidas <= 0) {
      _morir();
      return;
    }
    invencible = 1.5;
    paco.vy = -9;
    paco.vx = paco.centroX < desdeX ? -6 : 6;
  }

  void _morir() {
    if (estado != Estado.jugando) return;
    estado = Estado.muerto;
    tiempoMuerto = 0;
    vidas = 0;
    paco.vy = -12;
  }

  void _reaparecer() {
    estado = Estado.jugando;
    vidas = 3;
    invencible = 1.5;
    puertaCerrada = false;
    // Si la puerta del jefe estaba cerrada, se vuelve a abrir
    final arena = mapa.arenaX;
    if (arena != null) {
      final col = arena.floor() - 1;
      final techo = nivel.tipo == TipoNivel.fortaleza ? 2 : 1;
      for (var y = techo; y < mapa.sueloArena; y++) {
        mapa.poner(col, y, Casilla.vacio);
      }
    }
    _colocarPaco();
    _crearEnemigos();
  }

  void _ganar() {
    if (estado != Estado.jugando) return;
    estado = Estado.ganado;
    tiempoGanado = 0;
  }

  /// Ya se puede mostrar la pantalla de nivel completado.
  bool get terminado => estado == Estado.ganado && tiempoGanado > 1.6;

  /// Reiniciar el nivel desde el principio.
  void reiniciar() {
    mapa = generarMapa(nivel);
    pescados = 0;
    control = false;
    puertaCerrada = false;
    estado = Estado.jugando;
    vidas = 3;
    invencible = 0;
    _colocarPaco();
    _crearEnemigos();
  }
}
