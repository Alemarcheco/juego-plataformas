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
  double disparo = 2;

  /// El perro de espinas se infla antes de explotar.
  double inflar = 0;

  /// Los perros que lanzan cosas se paran y brillan un momento antes.
  double aviso = 0;

  /// En el mundo secreto los enemigos son gigantes.
  double tamano = 1;

  Enemigo(this.tipo, double x, double y, double w, double h, this.t)
      : baseX = x,
        baseY = y,
        super(x, y, w, h);

  bool get pisable =>
      tipo != TipoEnemigo.fuego &&
      tipo != TipoEnemigo.espinoso &&
      tipo != TipoEnemigo.pezGlobo;

  bool get camina => const {
        TipoEnemigo.perro,
        TipoEnemigo.saltarin,
        TipoEnemigo.hielo,
        TipoEnemigo.llamas,
        TipoEnemigo.acido,
        TipoEnemigo.robot,
        TipoEnemigo.espinoso,
      }.contains(tipo);
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
  double t = 0;

  /// Embestida: se prepara (tiembla), corre y luego se queda mareado.
  ModoJefe modo = ModoJefe.normal;
  double tiempoModo = 0;
  double cargar = 3;
  double soltar = 1;
  bool enAire = false;
  int ataque = 0;

  /// Aviso antes de un ataque a distancia: el jefe brilla del color del
  /// ataque que viene ([proximo]) y luego ataca.
  double aviso = 0;
  Habilidad? proximo;

  /// Descanso después de cualquier ataque: nunca hace dos a la vez.
  double calma = 0;

  bool get libre => aviso <= 0 && calma <= 0 && modo == ModoJefe.normal;

  /// Jefes con jetpack que también caminan (el Perro Supremo) alternan
  /// entre andar y volar.
  bool faseVuelo = false;
  double tiempoFase = 9;

  JefeVivo(this.datos, double x, double y)
      : vidas = datos.vidas,
        super(x, y, 1.8 * datos.tamano, 1.6 * datos.tamano);
}

enum ModoJefe { normal, preparando, embistiendo, mareado }

/// Algo que lanza un jefe y hace daño a Paco.
class Proyectil extends Cuerpo {
  final TipoProyectil tipo;
  final double gravedad;
  double giro = 0;
  bool fuera = false;

  /// Tiempo de aviso antes de salir (las bolas de fuego del suelo).
  double espera;

  /// Tiempo hasta dividirse en 8 espinas (los copos de nieve).
  double dividir;

  /// Si es mayor que 0, desaparece al acabarse (las llamas).
  double vida;

  /// Quita todas las vidas de golpe (el ácido).
  final bool mortal;
  Proyectil(this.tipo, double x, double y, double w, double h,
      {double vx = 0,
      double vy = 0,
      this.gravedad = 0,
      this.espera = 0,
      this.dividir = 0,
      this.vida = 0,
      this.mortal = false})
      : super(x, y, w, h) {
    this.vx = vx;
    this.vy = vy;
  }
}

/// Teclas o botones que se están pulsando.
class Mandos {
  bool izquierda = false;
  bool derecha = false;
  bool salto = false;
}

enum Estado { jugando, muerto, ganado }

/// Un gato en el modo de dos jugadores. El motor trabaja siempre con el
/// gato "activo" (paco, mandos, vidas...) y los va cambiando.
class Jugador {
  Cuerpo cuerpo = Cuerpo(0, 0, 0.8, 0.9);
  Mandos mandos = Mandos();
  int vidas = 3;
  double invencible = 0;
  int dir = 1;
  double pasos = 0;
  double coyote = 0;
  double bufferSalto = 0;
  bool saltoAntes = false;

  /// Tiempo desde que se cayó; menor que 0 si está vivo.
  double muerto = -1;
  bool get vivo => muerto < 0;
}

/// Toda la lógica de un nivel en marcha.
class Motor {
  final Nivel nivel;
  late Mapa mapa;
  Cuerpo paco = Cuerpo(0, 0, 0.8, 0.9);
  final List<Enemigo> enemigos = [];
  final List<Proyectil> proyectiles = [];
  JefeVivo? jefe;
  Mandos mandos = Mandos();

  /// Modo de dos jugadores en el mismo teléfono (vacío si juega uno solo).
  final List<Jugador> jugadores = [];
  Jugador? _activo;

  Estado estado = Estado.jugando;
  int vidas = 3;
  int pescados = 0;
  int totalPescados = 0;
  double t = 0;
  double invencible = 0;
  double tiempoMuerto = 0;
  double tiempoGanado = 0;
  bool control = false;

  /// Enemigos pisados desde la última vez que la pantalla los contó.
  final List<TipoEnemigo> derrotados = [];

  /// Efectos de sonido que tocan (la pantalla los toca y vacía la lista).
  final List<String> sonidos = [];
  bool puertaCerrada = false;

  /// Paco entró en el portal del mundo secreto.
  bool secretoEncontrado = false;
  int dirPaco = 1;
  double pasos = 0;

  double camX = 0;
  double anchoVista = 26;

  // Ayudas para que el salto se sienta bien
  double _coyote = 0;
  double _bufferSalto = 0;
  bool _saltoAntes = false;

  bool get enAgua =>
      nivel.tipo == TipoNivel.agua ||
      (nivel.arenaAcuatica && mapa.arenaX != null && paco.x > mapa.arenaX! - 1);

  /// Construye el mapa; los niveles del creador traen el suyo.
  final Mapa Function() _hacerMapa;

  Motor(this.nivel, {Mapa Function()? crearMapa, bool dosJugadores = false})
      : _hacerMapa = crearMapa ?? (() => generarMapa(nivel)) {
    if (dosJugadores) jugadores.addAll([Jugador(), Jugador()]);
    mapa = _hacerMapa();
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
    final y = control
        ? (mapa.controlY ?? mapa.suelo(mapa.controlX.floor())) - 1.0
        : mapa.inicioY;
    paco = Cuerpo(x, enAgua && !control ? mapa.inicioY : y, 0.8, 0.9);
    dirPaco = 1;
    camX = max(0, paco.x - anchoVista * 0.35);
    // Con dos jugadores, el segundo sale justo detrás
    for (final (i, j) in jugadores.indexed) {
      j.cuerpo = Cuerpo(paco.x - i * 0.9, paco.y, 0.8, 0.9);
      j.dir = 1;
      j.vidas = 3;
      j.invencible = 0;
      j.muerto = -1;
    }
    if (jugadores.isNotEmpty) usar(jugadores.first);
  }

  // ------------------------------------------------------ dos jugadores
  /// Pone a este gato como el activo (paco, mandos, vidas...).
  void usar(Jugador j) {
    _activo = j;
    paco = j.cuerpo;
    mandos = j.mandos;
    vidas = j.vidas;
    invencible = j.invencible;
    dirPaco = j.dir;
    pasos = j.pasos;
    _coyote = j.coyote;
    _bufferSalto = j.bufferSalto;
    _saltoAntes = j.saltoAntes;
  }

  void _guardar(Jugador j) {
    j.cuerpo = paco;
    j.vidas = vidas;
    j.invencible = invencible;
    j.dir = dirPaco;
    j.pasos = pasos;
    j.coyote = _coyote;
    j.bufferSalto = _bufferSalto;
    j.saltoAntes = _saltoAntes;
  }

  void _pasoDosJugadores(double dt) {
    final vivos = jugadores.where((j) => j.vivo).toList();
    for (final j in jugadores) {
      usar(j);
      if (j.vivo) {
        _actualizarPaco(dt);
      } else {
        // Se cae dando vueltas y vuelve junto al otro gato
        j.muerto += dt;
        paco.vy += 30 * dt;
        paco.y += paco.vy * dt;
        final otro = jugadores.firstWhere((o) => o != j);
        if (j.muerto > 2 && otro.vivo && otro.cuerpo.y < Mapa.alto - 2) {
          j.muerto = -1;
          paco = Cuerpo(otro.cuerpo.x, max(0, otro.cuerpo.y - 2), 0.8, 0.9);
          vidas = 3;
          invencible = 2;
        }
      }
      _guardar(j);
      if (estado != Estado.jugando) return;
    }
    // Los enemigos persiguen al primer gato vivo; el otro solo choca con ellos
    if (vivos.isEmpty) return;
    usar(vivos.first);
    _actualizarEnemigos(dt);
    _actualizarJefe(dt);
    _actualizarProyectiles(dt);
    _guardar(vivos.first);
    for (final j in vivos.skip(1)) {
      if (!j.vivo) continue;
      usar(j);
      for (final e in enemigos) {
        if (e.vivo && e.activo) _contacto(e);
      }
      final jf = jefe;
      if (jf != null && jf.activo && jf.derrotado == 0) _contacto(jf);
      for (final p in proyectiles) {
        if (!p.fuera && p.espera <= 0) _proyectilToca(p);
      }
      proyectiles.removeWhere((p) => p.fuera);
      _guardar(j);
    }
    _camaraDos();
  }

  /// La cámara mira entre los dos gatos y ninguno se puede salir de ella.
  void _camaraDos() {
    final vivos = jugadores.where((j) => j.vivo).toList();
    if (vivos.isEmpty) return;
    final medio = vivos.map((j) => j.cuerpo.centroX).reduce((a, b) => a + b) /
        vivos.length;
    final objetivo = medio - anchoVista * 0.45;
    camX += (objetivo - camX) * 0.18;
    camX = camX.clamp(0, max(0.0, mapa.ancho - anchoVista));
    final arena = mapa.arenaX;
    if (puertaCerrada && arena != null) {
      camX = max(camX, min(arena - 1, mapa.ancho - anchoVista));
    }
    for (final j in vivos) {
      final c = j.cuerpo;
      if (c.x < camX) {
        c.x = camX;
        if (c.vx < 0) c.vx = 0;
      }
      if (c.x + c.w > camX + anchoVista) {
        c.x = camX + anchoVista - c.w;
        if (c.vx > 0) c.vx = 0;
      }
    }
    if (_activo != null) usar(_activo!);
  }

  void _crearEnemigos() {
    enemigos.clear();
    proyectiles.clear();
    final rnd = Random(nivel.indice);
    // En el mundo secreto los perros y los peces son gigantes
    final g = nivel.esSecreto ? 1.7 : 1.0;
    for (final a in mapa.enemigos) {
      final fase = rnd.nextDouble() * 6;
      final antes = enemigos.length;
      switch (a.tipo) {
        case TipoEnemigo.perro:
        case TipoEnemigo.saltarin:
        case TipoEnemigo.hielo:
        case TipoEnemigo.llamas:
        case TipoEnemigo.acido:
        case TipoEnemigo.robot:
        case TipoEnemigo.espinoso:
          enemigos.add(Enemigo(a.tipo, a.x, a.y - 0.8 * g, 0.95 * g, 0.8 * g, fase));
        case TipoEnemigo.volador:
          enemigos.add(Enemigo(a.tipo, a.x, a.y - 0.7 * (g - 1), 0.9 * g, 0.7 * g, fase));
        case TipoEnemigo.pez:
        case TipoEnemigo.pezGlobo:
        case TipoEnemigo.pezHielo:
        case TipoEnemigo.pezMorado:
          enemigos.add(Enemigo(a.tipo, a.x, a.y - 0.65 * (g - 1), 0.95 * g, 0.65 * g, fase));
        case TipoEnemigo.fuego:
          enemigos.add(Enemigo(a.tipo, a.x, a.y, 0.75, 0.75, fase));
      }
      if (a.tipo != TipoEnemigo.fuego) {
        for (final e in enemigos.skip(antes)) {
          e.tamano = g;
        }
      }
    }
    final datos = nivel.jefe;
    if (datos != null && mapa.arenaX != null) {
      jefe = JefeVivo(datos, mapa.ancho - 7.0, mapa.sueloArena - 1.6 * datos.tamano);
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
    if (jugadores.isNotEmpty) {
      _pasoDosJugadores(dt);
      return;
    }
    _actualizarPaco(dt);
    _actualizarEnemigos(dt);
    _actualizarJefe(dt);
    _actualizarProyectiles(dt);
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
      if (pulsado) {
        p.vy = -6.8;
        sonidos.add('nadar');
      }
    } else {
      if (p.enSuelo) _coyote = 0.1;
      _coyote -= dt;
      if (_bufferSalto > 0 && _coyote > 0) {
        p.vy = -16.5;
        sonidos.add('salto');
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
            sonidos.add('pescado');
          case Casilla.corazon:
            mapa.poner(x, y, Casilla.vacio);
            vidas = min(5, vidas + 1);
            sonidos.add('corazon');
          case Casilla.liquido:
            if (p.y + p.h > y + 0.3) _morir();
          case Casilla.pinchos:
            if (p.y + p.h > y + 0.45) _herir(desdeX: x + 0.5);
          case Casilla.portal:
            if (!secretoEncontrado) sonidos.add('portal');
            secretoEncontrado = true;
            _ganar();
          default:
            break;
        }
      }
    }
    if (p.y > Mapa.alto + 1) _morir();

    if (!control && mapa.controlX > 0 && p.x >= mapa.controlX) {
      control = true;
      sonidos.add('bandera');
    }

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
        case TipoEnemigo.hielo:
        case TipoEnemigo.llamas:
        case TipoEnemigo.acido:
        case TipoEnemigo.robot:
        case TipoEnemigo.espinoso:
          if (_atacaEnemigo(e, dt)) continue;
          e.vx = e.dir * vel * (e.tipo == TipoEnemigo.perro || e.tipo == TipoEnemigo.saltarin ? 1 : 0.6);
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
        case TipoEnemigo.pezGlobo:
        case TipoEnemigo.pezHielo:
          if (_atacaPez(e, dt)) continue;
          final nx = e.baseX + sin(e.t * 0.6) * 3;
          e.dir = nx >= e.x ? 1 : -1;
          e.x = nx;
          e.y = e.baseY + sin(e.t * 1.5) * 0.6;
        case TipoEnemigo.pezMorado:
          // Persigue a Paco cuando lo ve, si no da vueltas
          final dx = p.centroX - e.centroX;
          final dy = (p.y + p.h / 2) - (e.y + e.h / 2);
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < 9 && dist > 0.01) {
            e.vx = dx / dist * 2.3;
            e.vy = dy / dist * 2.3;
          } else {
            e.vx = cos(e.t * 0.6) * 1.2;
            e.vy = sin(e.t * 1.5) * 0.6;
          }
          if (e.vx.abs() > 0.05) e.dir = e.vx > 0 ? 1 : -1;
          mover(e, dt);
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

  /// Ataques de los perros especiales. Devuelve true si el perro ya no sigue.
  bool _atacaEnemigo(Enemigo e, double dt) {
    final dx = paco.centroX - e.centroX;
    final dy = (paco.y + paco.h / 2) - (e.y + e.h / 2);
    switch (e.tipo) {
      case TipoEnemigo.espinoso:
        if (e.inflar > 0) {
          e.inflar += dt;
          e.vx = 0;
          if (e.inflar > 0.8) {
            for (var k = 0; k < 8; k++) {
              final a = k * pi / 4;
              proyectiles.add(Proyectil(TipoProyectil.espina, e.centroX - 0.2,
                  e.y + e.h / 2 - 0.2, 0.4, 0.4,
                  vx: cos(a) * 6, vy: sin(a) * 6, vida: 0.6));
            }
            e.vivo = false;
            e.aplastado = 1; // no deja cuerpo aplastado
            sonidos.add('explosion');
            return true;
          }
          _contacto(e);
          return true;
        }
        if (dx.abs() < 2.6 && dy.abs() < 2) e.inflar = 0.001;
      case TipoEnemigo.hielo:
      case TipoEnemigo.llamas:
      case TipoEnemigo.acido:
      case TipoEnemigo.robot:
        if (e.aviso > 0) {
          // Se para, mira a Paco y brilla; luego lanza
          e.aviso -= dt;
          e.vx = 0;
          e.vy += (enAgua ? 11 : 40) * dt;
          mover(e, dt);
          if (e.aviso <= 0) {
            _lanzaEnemigo(e);
          } else {
            e.dir = paco.centroX > e.centroX ? 1 : -1;
          }
          _contacto(e);
          return true;
        }
        e.disparo -= dt;
        final alcance = e.tipo == TipoEnemigo.llamas ? 5.0 : 10.0;
        if (e.disparo <= 0 && dx.abs() < alcance && dy.abs() < 3) {
          e.disparo = switch (e.tipo) {
            TipoEnemigo.llamas => 2.2,
            TipoEnemigo.robot => 3.6,
            _ => 3.0,
          };
          e.dir = dx > 0 ? 1 : -1;
          e.aviso = 0.7;
        }
      default:
        break;
    }
    return false;
  }

  void _lanzaEnemigo(Enemigo e) {
    sonidos.add('lanzar');
    final x = e.centroX + e.dir * 0.5 - 0.25;
    final y = e.y + 0.15;
    switch (e.tipo) {
      case TipoEnemigo.hielo:
        proyectiles.add(Proyectil(TipoProyectil.espinaNieve, x, y, 0.45, 0.35,
            vx: e.dir * 6.0, vy: -4, gravedad: 9));
      case TipoEnemigo.llamas:
        for (var k = 0; k < 3; k++) {
          proyectiles.add(Proyectil(TipoProyectil.fuego, x, y + 0.1, 0.45, 0.45,
              vx: e.dir * (5.0 + k), vy: (k - 1) * 0.8, vida: 0.55));
        }
      case TipoEnemigo.acido:
        proyectiles.add(Proyectil(TipoProyectil.acido, x, y, 0.45, 0.45,
            vx: e.dir * 4.0, mortal: true));
      case TipoEnemigo.robot:
        // La bomba flota despacio hacia Paco y explota en 8 espinas
        proyectiles.add(Proyectil(TipoProyectil.bomba, x, y - 0.4, 0.6, 0.6,
            vx: e.dir * 2.2, vy: -1.2, gravedad: 1.2, dividir: 1.8));
      default:
        break;
    }
  }

  /// Ataques de los peces especiales. Devuelve true si el pez ya no sigue.
  bool _atacaPez(Enemigo e, double dt) {
    final dx = paco.centroX - e.centroX;
    final dy = (paco.y + paco.h / 2) - (e.y + e.h / 2);
    switch (e.tipo) {
      case TipoEnemigo.pezGlobo:
        if (e.inflar > 0) {
          e.inflar += dt;
          if (e.inflar > 0.8) {
            for (var k = 0; k < 8; k++) {
              final a = k * pi / 4;
              proyectiles.add(Proyectil(TipoProyectil.espina, e.centroX - 0.2,
                  e.y + e.h / 2 - 0.2, 0.4, 0.4,
                  vx: cos(a) * 5, vy: sin(a) * 5, vida: 0.7));
            }
            e.vivo = false;
            e.aplastado = 1;
            sonidos.add('explosion');
          } else {
            _contacto(e);
          }
          return true;
        }
        if (dx.abs() < 2.4 && dy.abs() < 2.4) e.inflar = 0.001;
      case TipoEnemigo.pezHielo:
        if (e.aviso > 0) {
          e.aviso -= dt;
          e.dir = dx > 0 ? 1 : -1;
          if (e.aviso <= 0) {
            proyectiles.add(Proyectil(TipoProyectil.espinaNieve,
                e.centroX + e.dir * 0.5 - 0.22, e.y + e.h / 2 - 0.17, 0.45, 0.35,
                vx: e.dir * 5.5));
          }
          _contacto(e);
          return true;
        }
        e.disparo -= dt;
        if (e.disparo <= 0 && dx.abs() < 9 && dy.abs() < 1.5) {
          e.disparo = 2.6;
          e.aviso = 0.7;
        }
      default:
        break;
    }
    return false;
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
        derrotados.add(e.tipo);
        sonidos.add('pisar');
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
    sonidos.add('golpe_jefe');
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
    if (j.calma > 0) j.calma -= dt;
    j.t += dt;
    final d = j.datos;
    final furia = 1 - j.vidas / d.vidas; // 0 al principio, ~1 al final
    final vel = 1.8 + dificultad * 0.1 + furia * 1.2;
    final arena = mapa.arenaX ?? 0;
    final haciaPaco = paco.centroX > j.centroX ? 1 : -1;

    if (d.sabe(Habilidad.jetpack) && !d.sabe(Habilidad.volar) &&
        j.modo == ModoJefe.normal) {
      j.tiempoFase -= dt;
      if (j.tiempoFase <= 0) {
        j.faseVuelo = !j.faseVuelo;
        j.tiempoFase = j.faseVuelo ? 6 : 9;
      }
    }
    final vuela = d.sabe(Habilidad.volar) || j.faseVuelo;
    if (vuela) {
      // Vuela o nada: sigue a Paco despacio y sube y baja para que se le pueda pisar.
      j.dir = haciaPaco;
      j.vx = (paco.centroX - j.centroX).clamp(-1.0, 1.0) * vel * 0.8;
      final base = mapa.sueloArena - j.h - 2.6;
      final objetivoY = base + sin(j.t * 1.3) * 2.5;
      j.vy = (objetivoY - j.y) * 3;
      mover(j, dt);
      if (d.sabe(Habilidad.jetpack)) {
        j.soltar -= dt;
        // No suelta fuego si está avisando o va a tocarle otro ataque
        if (j.soltar <= 0 && j.libre && j.lanzar > 0.6) {
          j.soltar = 1.4 - furia * 0.4;
          j.calma = 0.6;
          proyectiles.add(Proyectil(TipoProyectil.fuego,
              j.centroX - j.dir * 0.7 - 0.25, j.abajo - 0.2, 0.5, 0.5,
              vy: 1.2));
        }
      }
    } else {
      switch (j.modo) {
        case ModoJefe.normal:
          if (j.x < arena + 1) j.dir = 1;
          if (j.x > mapa.ancho - 3) j.dir = -1;
          j.vx = j.dir * vel;
          if (d.sabe(Habilidad.saltar) && j.enSuelo) {
            j.espera -= dt;
            if (j.espera <= 0) {
              j.vy = enAgua ? -9 : -13;
              j.espera = 1.2 + (1 - furia) * 1.3;
              j.dir = haciaPaco;
            }
          }
          if (d.sabe(Habilidad.embestir) && j.enSuelo) {
            j.cargar -= dt;
            if (j.cargar <= 0 && j.libre) {
              j.modo = ModoJefe.preparando;
              j.tiempoModo = 0.8;
              j.dir = haciaPaco;
            }
          }
        case ModoJefe.preparando:
          j.vx = 0;
          j.tiempoModo -= dt;
          if (j.tiempoModo <= 0) {
            j.modo = ModoJefe.embistiendo;
            j.tiempoModo = 2.0;
          }
        case ModoJefe.embistiendo:
          j.vx = j.dir * (6.5 + furia * 2);
          j.tiempoModo -= dt;
          if (j.chocoPared || j.tiempoModo <= 0) {
            j.modo = ModoJefe.mareado;
            j.tiempoModo = 1.2;
          }
        case ModoJefe.mareado:
          j.vx = 0;
          j.tiempoModo -= dt;
          if (j.tiempoModo <= 0) {
            j.modo = ModoJefe.normal;
            j.calma = 1.0;
            j.cargar = 3.5 - furia * 1.5;
            j.dir = haciaPaco;
          }
      }
      final g = enAgua ? 14.0 : 40.0;
      j.vy += g * dt;
      if (j.vy > 18) j.vy = 18;
      mover(j, dt);
      if (j.chocoPared && j.modo == ModoJefe.normal) j.dir = -j.dir;
      // Al caer de un salto, onda por el suelo
      if (j.enAire && j.enSuelo && d.sabe(Habilidad.onda) && j.libre) {
        j.calma = 0.8;
        for (final lado in [-1.0, 1.0]) {
          proyectiles.add(Proyectil(TipoProyectil.onda,
              j.centroX - 0.4 + lado * 0.9, mapa.sueloArena - 0.6, 0.8, 0.6,
              vx: lado * 6));
        }
      }
      j.enAire = !j.enSuelo;
    }

    // Ataques a distancia, uno detrás de otro
    final ataques = [
      if (d.sabe(Habilidad.lanzarArco)) Habilidad.lanzarArco,
      if (d.sabe(Habilidad.disparar)) Habilidad.disparar,
      if (d.sabe(Habilidad.lluvia)) Habilidad.lluvia,
      if (d.sabe(Habilidad.erupcion)) Habilidad.erupcion,
    ];
    if (j.aviso > 0) {
      j.aviso -= dt;
      if (j.aviso <= 0) {
        _atacar(j, j.proximo!, paco.centroX > j.centroX ? 1 : -1, furia);
        j.ataque++;
        j.proximo = null;
        j.lanzar = 3.2 - furia * 0.9;
        j.calma = 1.0;
      }
    } else if (ataques.isNotEmpty && j.modo == ModoJefe.normal) {
      if (j.lanzar > 0) j.lanzar -= dt;
      if (j.lanzar <= 0 && j.libre) {
        j.proximo = ataques[j.ataque % ataques.length];
        sonidos.add('aviso');
        j.aviso = 0.8 - furia * 0.2;
      }
    }
    if (estado == Estado.jugando) _contacto(j);
  }

  static const _arcosSupremo = [
    TipoProyectil.hueso,
    TipoProyectil.espina,
    TipoProyectil.pescado,
    TipoProyectil.copo,
    TipoProyectil.veneno,
    TipoProyectil.estrella,
  ];

  void _atacar(JefeVivo j, Habilidad h, int hacia, double furia) {
    sonidos.add('lanzar');
    var tipo = j.datos.proyectil;
    if (j.datos.disfraz == Disfraz.supremo) {
      // El Perro Supremo usa los ataques de todos los jefes
      tipo = switch (h) {
        Habilidad.disparar => TipoProyectil.laser,
        Habilidad.lluvia => TipoProyectil.roca,
        Habilidad.erupcion => TipoProyectil.fuego,
        _ => _arcosSupremo[(j.ataque ~/ 4) % _arcosSupremo.length],
      };
    }
    switch (h) {
      case Habilidad.lanzarArco:
        final distancia = (paco.centroX - j.centroX).abs();
        final rapidez = (distancia * 0.9).clamp(3.0, 8.0);
        final seRompe =
            tipo == TipoProyectil.copo || tipo == TipoProyectil.veneno;
        final cuantos = seRompe ? 1 : (furia > 0.5 ? 3 : 1);
        for (var i = 0; i < cuantos; i++) {
          proyectiles.add(Proyectil(tipo, j.centroX - 0.3, j.y + 0.2, 0.6, 0.4,
              vx: hacia * (rapidez + i * 1.2),
              vy: enAgua ? -5.0 - i : -9.0 - i,
              gravedad: enAgua ? 8 : 20,
              dividir: tipo == TipoProyectil.copo
                  ? 0.9
                  : tipo == TipoProyectil.veneno
                      ? 1.1
                      : 0));
        }
      case Habilidad.disparar:
        final y = (paco.y + paco.h / 2 - 0.15)
            .clamp(j.y, j.y + j.h - 0.3)
            .toDouble();
        proyectiles.add(Proyectil(tipo, j.centroX - 0.5, y, 1.0, 0.3,
            vx: hacia * (enAgua ? 6.0 : 9.0)));
      case Habilidad.lluvia:
        final arriba = nivel.tipo == TipoNivel.fortaleza ? 2.0 : 1.0;
        for (final dx in [-2.5, 0.0, 2.5]) {
          proyectiles.add(Proyectil(tipo, paco.centroX + dx - 0.3, arriba, 0.6, 0.6,
              gravedad: enAgua ? 6 : 12));
        }
      case Habilidad.erupcion:
        // El suelo brilla un momento y luego sale el fuego
        final cuantas = furia > 0.5 ? 3 : 2;
        for (var i = 0; i < cuantas; i++) {
          final x = paco.centroX - 0.35 + (i - (cuantas - 1) / 2) * 2.2;
          proyectiles.add(Proyectil(TipoProyectil.fuego, x,
              mapa.sueloArena - 0.7, 0.7, 0.7,
              vy: -15, gravedad: 22, espera: 0.9));
        }
      default:
        break;
    }
  }

  /// Un proyectil que toca a Paco le hace daño. Devuelve true si la bomba
  /// tiene que explotar ya.
  bool _proyectilToca(Proyectil p) {
    if (!p.toca(paco)) return false;
    if (p.tipo == TipoProyectil.bomba) {
      p.dividir = 0.0001; // la bomba explota al tocar a Paco
      return true;
    }
    if (p.mortal) {
      if (invencible <= 0) _morir();
    } else {
      _herir(desdeX: p.centroX);
    }
    p.fuera = true;
    return false;
  }

  void _actualizarProyectiles(double dt) {
    final nuevos = <Proyectil>[];
    for (final p in proyectiles) {
      if (p.espera > 0) {
        p.espera -= dt;
        continue;
      }
      if (p.dividir > 0) {
        p.dividir -= dt;
        if (p.dividir <= 0) {
          // El copo se rompe en 8 espinas de nieve; la burbuja de veneno
          // explota en gotas
          if (p.tipo == TipoProyectil.bomba) {
            sonidos.add('explosion');
            for (var k = 0; k < 8; k++) {
              final a = k * pi / 4;
              nuevos.add(Proyectil(TipoProyectil.espina, p.centroX - 0.2,
                  p.y + p.h / 2 - 0.2, 0.4, 0.4,
                  vx: cos(a) * 6, vy: sin(a) * 6, vida: 0.9));
            }
            p.fuera = true;
            continue;
          }
          final copo = p.tipo == TipoProyectil.copo;
          final trozos = copo ? 8 : 6;
          for (var k = 0; k < trozos; k++) {
            final a = k * 2 * pi / trozos - (copo ? 0 : pi / 2);
            nuevos.add(Proyectil(
                copo ? TipoProyectil.espinaNieve : TipoProyectil.gota,
                p.centroX - 0.2,
                p.y + p.h / 2 - 0.2,
                0.4,
                0.4,
                vx: cos(a) * (copo ? 6 : 4.5),
                vy: sin(a) * (copo ? 6 : 4.5) - (copo ? 0 : 3),
                gravedad: copo ? 0 : 12));
          }
          p.fuera = true;
          continue;
        }
      }
      if (p.vida > 0) {
        p.vida -= dt;
        if (p.vida <= 0) {
          p.fuera = true;
          continue;
        }
      }
      p.vy += p.gravedad * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.giro += dt * 8;
      if (_proyectilToca(p)) continue;
      final cx = p.centroX.floor();
      final cy = p.abajo.floor();
      if (p.tipo == TipoProyectil.onda) {
        if (esSolida(mapa.en((p.x + (p.vx > 0 ? p.w : 0)).floor(), p.y.floor()))) {
          p.fuera = true;
        }
      } else if (esSolida(mapa.en(cx, cy)) || esSolida(mapa.en(cx, p.y.floor()))) {
        if (p.dividir > 0) {
          p.dividir = 0.0001; // al tocar el suelo también se rompe
          p.y -= 0.3;
        } else if (!(p.gravedad > 0 && p.vy < 0)) {
          p.fuera = true; // lo que sube desde el suelo no choca hasta bajar
        }
      }
      if (p.y > Mapa.alto + 1 || p.x < camX - 4 || p.x > camX + anchoVista + 4) {
        p.fuera = true;
      }
    }
    proyectiles.removeWhere((p) => p.fuera);
    proyectiles.addAll(nuevos);
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
    sonidos.add('herido');
    paco.vy = -9;
    paco.vx = paco.centroX < desdeX ? -6 : 6;
  }

  void _morir() {
    if (estado != Estado.jugando) return;
    if (_activo == null || _activo!.vivo) sonidos.add('morir');
    final activo = _activo;
    if (jugadores.isNotEmpty && activo != null) {
      // Con dos jugadores solo se cae este gato; si se caen los dos, se
      // vuelve a empezar desde la bandera
      if (!activo.vivo) return;
      activo.muerto = 0;
      vidas = 0;
      paco.vy = -12;
      if (jugadores.any((j) => j.vivo)) return;
    }
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
    if (!secretoEncontrado) sonidos.add('ganar');
    estado = Estado.ganado;
    tiempoGanado = 0;
  }

  /// Ya se puede mostrar la pantalla de nivel completado.
  bool get terminado => estado == Estado.ganado && tiempoGanado > 1.6;

  /// Reiniciar el nivel desde el principio.
  void reiniciar() {
    mapa = _hacerMapa();
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
