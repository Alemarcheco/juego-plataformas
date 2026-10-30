import 'dart:math';

import 'package:flutter/material.dart';

import '../datos/mundos.dart';
import '../datos/skins.dart';
import '../progreso.dart';
import 'generador.dart';
import 'motor.dart';

/// Dibuja el nivel completo: fondo, casillas, enemigos y Paco.
class PintorJuego extends CustomPainter {
  final Motor motor;
  PintorJuego(this.motor, Listenable repintar) : super(repaint: repintar);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / Mapa.alto;
    motor.anchoVista = size.width / s;
    final tema = motor.nivel.tema;
    final cam = motor.camX;

    // Cielo
    final cielo = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tema.cieloArriba, tema.cieloAbajo],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, cielo);
    _decorado(canvas, size, s, cam, tema);

    canvas.save();
    canvas.translate(-cam * s, 0);
    _casillas(canvas, s, cam);
    final arena = motor.mapa.arenaX;
    if (motor.nivel.arenaAcuatica && arena != null) {
      // La pelea con el jefe es dentro del mar
      final x0 = (arena - 1) * s;
      final ola = sin(motor.t * 2) * s * 0.1;
      canvas.drawRect(
          Rect.fromLTRB(x0, s * 2.5 + ola, motor.mapa.ancho * s, motor.mapa.sueloArena * s),
          Paint()..color = (tema.liquido ?? Colors.blue).withValues(alpha: 0.45));
    }
    _banderas(canvas, s);
    for (final e in motor.enemigos) {
      _enemigo(canvas, s, e);
    }
    final j = motor.jefe;
    if (j != null) _jefe(canvas, s, j);
    for (final p in motor.proyectiles) {
      _proyectil(canvas, s, p);
    }
    _paco(canvas, s);
    canvas.restore();

    if (motor.enAgua) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = const Color(0xFF0A4A80).withValues(alpha: 0.12));
    }
  }

  // ------------------------------------------------------------- decorado
  void _decorado(Canvas c, Size size, double s, double cam, Tema tema) {
    final base = Color.lerp(tema.cieloAbajo, tema.cieloArriba, 0.35)!;
    final lejos = Paint()..color = Color.lerp(base, Colors.black, 0.12)!;
    final cerca = Paint()..color = Color.lerp(base, Colors.black, 0.25)!;
    final blanco = Paint()..color = Colors.white.withValues(alpha: 0.75);
    final h = size.height;

    void repetir(double paralaje, double separacion,
        void Function(double x, int i) dibujar) {
      final despl = cam * s * paralaje;
      final primero = (despl / separacion).floor() - 1;
      final ultimo = ((despl + size.width) / separacion).ceil() + 1;
      for (var i = primero; i <= ultimo; i++) {
        dibujar(i * separacion - despl, i);
      }
    }

    double azar(int i, int sal) {
      final v = sin(i * 12.9898 + sal * 78.233) * 43758.5453;
      return v - v.floorToDouble();
    }

    switch (tema.decorado) {
      case Decorado.colinas:
        repetir(0.15, s * 9, (x, i) {
          c.drawOval(
              Rect.fromCenter(
                  center: Offset(x, h * 0.85),
                  width: s * (10 + azar(i, 1) * 6),
                  height: s * (6 + azar(i, 2) * 4)),
              lejos);
        });
        repetir(0.05, s * 13, (x, i) => _nube(c, x, h * (0.12 + azar(i, 3) * 0.2), s, blanco));
      case Decorado.nubes:
        repetir(0.1, s * 7, (x, i) => _nube(c, x, h * (0.15 + azar(i, 1) * 0.6), s * (0.8 + azar(i, 2)), blanco));
        repetir(0.25, s * 11, (x, i) => _nube(c, x, h * (0.3 + azar(i, 4) * 0.5), s * 1.4, Paint()..color = Colors.white.withValues(alpha: 0.5)));
      case Decorado.arboles:
        repetir(0.2, s * 3, (x, i) {
          final alto = s * (5 + azar(i, 1) * 4);
          c.drawRect(Rect.fromLTWH(x - s * 0.2, h - alto, s * 0.4, alto), cerca);
          c.drawCircle(Offset(x, h - alto), s * (1.4 + azar(i, 2)), lejos);
        });
      case Decorado.arbolesSecos:
        final rama = Paint()
          ..color = Color.lerp(base, Colors.black, 0.45)!
          ..strokeWidth = s * 0.25
          ..strokeCap = StrokeCap.round;
        repetir(0.2, s * 4, (x, i) {
          final alto = s * (6 + azar(i, 1) * 4);
          c.drawLine(Offset(x, h), Offset(x, h - alto), rama..strokeWidth = s * 0.4);
          c.drawLine(Offset(x, h - alto * 0.6), Offset(x - s * 1.5, h - alto * 0.85), rama..strokeWidth = s * 0.2);
          c.drawLine(Offset(x, h - alto * 0.75), Offset(x + s * 1.3, h - alto), rama);
        });
        c.drawCircle(Offset(size.width * 0.8, h * 0.18), s * 1.2, Paint()..color = const Color(0xFFE8E4D0));
      case Decorado.muros:
        final ventana = Paint()..color = Color.lerp(tema.cieloArriba, Colors.black, 0.3)!;
        repetir(0.3, s * 6, (x, i) {
          c.drawRect(Rect.fromLTWH(x, h * 0.25, s * 1.2, h * 0.75), lejos);
          c.drawRRect(
              RRect.fromRectAndCorners(Rect.fromLTWH(x + s * 3, h * 0.35, s * 1, s * 1.8),
                  topLeft: Radius.circular(s * 0.5), topRight: Radius.circular(s * 0.5)),
              ventana);
        });
        // Antorchas
        repetir(0.3, s * 6, (x, i) {
          final llama = 0.8 + sin(motor.t * 9 + i) * 0.2;
          c.drawCircle(Offset(x + s * 5, h * 0.5), s * 0.3 * llama,
              Paint()..color = const Color(0xFFFFB347));
        });
      case Decorado.dunas:
        c.drawCircle(Offset(size.width * 0.75, h * 0.2), s * 1.6, Paint()..color = const Color(0xFFFFF2B0));
        repetir(0.15, s * 10, (x, i) {
          c.drawOval(Rect.fromCenter(center: Offset(x, h * 0.92), width: s * 16, height: s * 7), lejos);
        });
        final cactus = Paint()..color = const Color(0xFF5E9E4A);
        repetir(0.3, s * 8, (x, i) {
          final alto = s * (2.5 + azar(i, 3) * 2);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, h - alto - s * 2, s * 0.5, alto), Radius.circular(s * 0.25)), cactus);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + s * 0.5, h - alto - s * 1, s * 0.6, s * 0.3), Radius.circular(s * 0.15)), cactus);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + s * 0.85, h - alto - s * 1.8, s * 0.3, s * 1.0), Radius.circular(s * 0.15)), cactus);
        });
      case Decorado.palmeras:
        c.drawCircle(Offset(size.width * 0.8, h * 0.18), s * 1.5, Paint()..color = const Color(0xFFFFF0A0));
        c.drawRect(Rect.fromLTWH(0, h * 0.62, size.width, h * 0.38), Paint()..color = const Color(0xFF39A9E0));
        final tronco = Paint()..color = const Color(0xFF9A6A3A);
        final hoja = Paint()..color = const Color(0xFF3FA34D);
        repetir(0.25, s * 9, (x, i) {
          c.drawRect(Rect.fromLTWH(x, h * 0.35, s * 0.35, h * 0.3), tronco);
          for (var k = 0; k < 5; k++) {
            final a = -pi / 2 + (k - 2) * 0.6;
            c.drawOval(
                Rect.fromCenter(
                    center: Offset(x + cos(a) * s + s * 0.2, h * 0.35 + sin(a) * s * 0.4),
                    width: s * 2.2,
                    height: s * 0.5),
                hoja);
          }
        });
      case Decorado.corales:
        final coral = Paint()..color = const Color(0xFFE0707A).withValues(alpha: 0.45);
        repetir(0.25, s * 5, (x, i) {
          final alto = s * (2 + azar(i, 1) * 3);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, h - alto, s * 0.5, alto), Radius.circular(s * 0.25)), coral);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + s * 0.6, h - alto * 0.7, s * 0.4, alto * 0.7), Radius.circular(s * 0.2)), coral);
        });
        _burbujas(c, size, s, cam);
        _rayosDeLuz(c, size, s);
      case Decorado.burbujas:
        repetir(0.2, s * 8, (x, i) {
          c.drawOval(Rect.fromCenter(center: Offset(x, h * 0.95), width: s * 12, height: s * 5), lejos);
        });
        _burbujas(c, size, s, cam);
      case Decorado.montanasNieve:
        repetir(0.15, s * 10, (x, i) {
          final alto = h * (0.4 + azar(i, 1) * 0.25);
          final path = Path()
            ..moveTo(x - s * 6, h)
            ..lineTo(x, h - alto)
            ..lineTo(x + s * 6, h)
            ..close();
          c.drawPath(path, lejos);
          final pico = Path()
            ..moveTo(x - s * 1.5, h - alto + s * 2)
            ..lineTo(x, h - alto)
            ..lineTo(x + s * 1.5, h - alto + s * 2)
            ..close();
          c.drawPath(pico, Paint()..color = Colors.white);
        });
        for (var i = 0; i < 40; i++) {
          final px = (azar(i, 5) * size.width + motor.t * 15 * (0.5 + azar(i, 6))) % size.width;
          final py = (azar(i, 7) * h + motor.t * 30 * (0.5 + azar(i, 8))) % h;
          c.drawCircle(Offset(px, py), s * 0.08, blanco);
        }
      case Decorado.edificios:
        final luz = Paint()..color = const Color(0xFF34E0E0).withValues(alpha: 0.6);
        final rosa = Paint()..color = const Color(0xFFFF5AD9).withValues(alpha: 0.6);
        repetir(0.2, s * 4, (x, i) {
          final alto = h * (0.35 + azar(i, 1) * 0.45);
          c.drawRect(Rect.fromLTWH(x, h - alto, s * 3, alto), lejos);
          for (var k = 0; k < (alto / s / 1.2).floor(); k++) {
            c.drawRect(Rect.fromLTWH(x + s * 0.4, h - alto + s * (0.5 + k * 1.2), s * 2.2, s * 0.2),
                k.isEven ? luz : rosa);
          }
        });
        // Coches voladores
        repetir(0.5, s * 15, (x, i) {
          final cx = x + (motor.t * s * 3) % (s * 15);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx, h * (0.2 + azar(i, 3) * 0.2), s * 1.2, s * 0.4), Radius.circular(s * 0.2)), rosa);
        });
      case Decorado.cuadricula:
        final rejilla = Paint()
          ..color = const Color(0xFFB8C2CE)
          ..strokeWidth = 1;
        final paso = s * 2;
        final despl = (cam * s * 0.5) % paso;
        for (var x = -despl; x < size.width; x += paso) {
          c.drawLine(Offset(x, 0), Offset(x, h), rejilla);
        }
        for (var y = 0.0; y < h; y += paso) {
          c.drawLine(Offset(0, y), Offset(size.width, y), rejilla);
        }
        final azul = Paint()..color = const Color(0x332FA4FF);
        final naranja = Paint()..color = const Color(0x33FF9A2F);
        repetir(0.5, s * 12, (x, i) {
          c.drawRect(Rect.fromLTWH(x, h * 0.2, s * 2, s * 4), i.isEven ? azul : naranja);
        });
      case Decorado.ciudadAbajo:
        // La plataforma vuela muy por encima de la ciudad
        final lejana = Paint()..color = const Color(0x553A2A8A);
        final luz = Paint()..color = const Color(0x8834E0E0);
        repetir(0.08, s * 2.5, (x, i) {
          final alto = h * (0.12 + azar(i, 1) * 0.15);
          c.drawRect(Rect.fromLTWH(x, h - alto, s * 1.8, alto), lejana);
          c.drawRect(Rect.fromLTWH(x + s * 0.4, h - alto + s * 0.4, s * 0.3, s * 0.15), luz);
        });
        repetir(0.15, s * 9, (x, i) => _nube(c, x, h * (0.55 + azar(i, 2) * 0.25), s * 1.2, Paint()..color = Colors.white.withValues(alpha: 0.35)));
      case Decorado.gigante:
        // Hierba, flores y setas enormes: Paco es diminuto
        final hierba = Paint()..color = const Color(0xFF5CC85A);
        final hierbaOscura = Paint()..color = const Color(0xFF3A9A44);
        repetir(0.25, s * 3, (x, i) {
          final alto = h * (0.6 + azar(i, 1) * 0.35);
          final hoja = Path()
            ..moveTo(x - s * 0.8, h)
            ..quadraticBezierTo(x + s * (azar(i, 2) - 0.5) * 3, h - alto * 0.6, x + s * (azar(i, 3) - 0.5) * 4, h - alto)
            ..quadraticBezierTo(x + s * 0.2, h - alto * 0.5, x + s * 0.8, h)
            ..close();
          c.drawPath(hoja, i.isEven ? hierba : hierbaOscura);
        });
        repetir(0.12, s * 16, (x, i) {
          final alto = h * (0.55 + azar(i, 4) * 0.2);
          c.drawRect(Rect.fromLTWH(x - s * 0.3, h - alto, s * 0.6, alto), Paint()..color = const Color(0xFF4A9A3A));
          final centro = Offset(x, h - alto);
          final colores = [const Color(0xFFFF6B8A), const Color(0xFFFFD23F), const Color(0xFFB08AFF)];
          final petalo = Paint()..color = colores[i.abs() % 3];
          for (var k = 0; k < 6; k++) {
            final a = k * pi / 3;
            c.drawCircle(centro + Offset(cos(a) * s * 1.6, sin(a) * s * 1.6), s * 1.2, petalo);
          }
          c.drawCircle(centro, s * 1.1, Paint()..color = const Color(0xFFFFB020));
        });
        repetir(0.18, s * 23, (x, i) {
          c.drawRect(Rect.fromLTWH(x - s * 0.8, h - s * 4, s * 1.6, s * 4), Paint()..color = const Color(0xFFF4E8D0));
          c.drawArc(Rect.fromCenter(center: Offset(x, h - s * 4), width: s * 7, height: s * 5), pi, pi, true,
              Paint()..color = const Color(0xFFE0403A));
          for (var k = 0; k < 3; k++) {
            c.drawCircle(Offset(x - s * 1.8 + k * s * 1.8, h - s * 5.2 + (k % 2) * s * 0.6), s * 0.45, Paint()..color = Colors.white);
          }
        });
      case Decorado.volcanes:
        repetir(0.12, s * 14, (x, i) {
          final alto = h * (0.45 + azar(i, 1) * 0.2);
          final path = Path()
            ..moveTo(x - s * 7, h)
            ..lineTo(x - s * 1.2, h - alto)
            ..lineTo(x + s * 1.2, h - alto)
            ..lineTo(x + s * 7, h)
            ..close();
          c.drawPath(path, cerca);
          c.drawOval(Rect.fromCenter(center: Offset(x, h - alto), width: s * 2.4, height: s * 0.6),
              Paint()..color = const Color(0xFFFF7A1A));
        });
        for (var i = 0; i < 25; i++) {
          final px = (azar(i, 5) * size.width + sin(motor.t + i) * s) % size.width;
          final py = h - (azar(i, 7) * h + motor.t * 25 * (0.5 + azar(i, 8))) % h;
          c.drawCircle(Offset(px, py), s * 0.07, Paint()..color = const Color(0xFFFFB347));
        }
    }
  }

  void _nube(Canvas c, double x, double y, double s, Paint p) {
    c.drawCircle(Offset(x, y), s * 0.9, p);
    c.drawCircle(Offset(x + s, y - s * 0.4), s * 1.1, p);
    c.drawCircle(Offset(x + s * 2, y), s * 0.8, p);
    c.drawRect(Rect.fromLTWH(x, y - s * 0.2, s * 2, s * 0.9), p);
  }

  void _burbujas(Canvas c, Size size, double s, double cam) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05;
    for (var i = 0; i < 18; i++) {
      final v = sin(i * 91.7) * 1000;
      final fx = v - v.floorToDouble();
      final px = (fx * size.width * 1.3 - cam * s * 0.2) % size.width;
      final py = size.height - (motor.t * s * (1 + fx) + i * s * 2) % size.height;
      c.drawCircle(Offset(px + sin(motor.t * 2 + i) * s * 0.3, py), s * (0.1 + fx * 0.15), p);
    }
  }

  void _rayosDeLuz(Canvas c, Size size, double s) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.15 + i * 0.25) + sin(motor.t * 0.5 + i) * s;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + s * 1.5, 0)
        ..lineTo(x + s * 4, size.height)
        ..lineTo(x + s * 1, size.height)
        ..close();
      c.drawPath(path, p);
    }
  }

  // ------------------------------------------------------------- casillas
  /// Un trozo de coral ramificado (en lugar de un bloque de ladrillo).
  void _coral(Canvas c, Rect r, double s, int x, int y) {
    final m = motor.mapa;
    const colores = [Color(0xFFFF6F91), Color(0xFFFF9A5A), Color(0xFFB76CE0)];
    final color = colores[x % colores.length];
    final cuerpo = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final claro = Paint()..color = Color.lerp(color, Colors.white, 0.45)!;
    final oscuro = Paint()..color = Color.lerp(color, Colors.black, 0.25)!;
    final arriba = m.en(x, y - 1) == Casilla.ladrillo;
    final abajo = m.en(x, y + 1) == Casilla.ladrillo;
    // Crece desde el suelo (punta arriba) o cuelga del techo (punta abajo)
    final colgante = esSolida(m.en(x, y - 1)) && !esSolida(m.en(x, y + 1)) ||
        (m.en(x, y - 1) == Casilla.ladrillo && !esSolida(m.en(x, y + 1)) &&
            esSolida(m.en(x, y - 2)) && m.en(x, y - 2) != Casilla.ladrillo);
    final d = colgante ? 1.0 : -1.0; // hacia dónde crece
    final cx = r.left + s * 0.5;
    final base = colgante ? r.top : r.bottom;
    final punta = colgante ? r.bottom : r.top;
    final esPunta = colgante ? !abajo : !arriba;
    // Tronco
    c.drawLine(Offset(cx, base), Offset(cx, esPunta ? punta - d * s * 0.15 : punta),
        cuerpo..strokeWidth = s * 0.42);
    // Ramas que se abren a los lados y se curvan hacia la punta
    final lado = (x + y).isEven ? 1.0 : -1.0;
    for (final k in [lado, -lado]) {
      final y0 = base + d * s * (k == lado ? 0.35 : 0.6);
      final rama = Path()
        ..moveTo(cx, y0)
        ..quadraticBezierTo(cx + k * s * 0.42, y0, cx + k * s * 0.4, y0 + d * s * 0.32);
      c.drawPath(rama, cuerpo..strokeWidth = s * 0.24);
      c.drawCircle(Offset(cx + k * s * 0.4, y0 + d * s * 0.32), s * 0.12, claro);
    }
    if (esPunta) {
      c.drawCircle(Offset(cx, punta - d * s * 0.15), s * 0.17, claro);
    }
    // Pólipos
    for (var i = 0; i < 3; i++) {
      c.drawCircle(Offset(cx + (i - 1) * s * 0.06, base + d * s * (0.2 + i * 0.25)), s * 0.035, oscuro);
    }
  }

  void _casillas(Canvas c, double s, double cam) {
    final m = motor.mapa;
    final tema = motor.nivel.tema;
    final x0 = max(0, cam.floor() - 1);
    final x1 = min(m.ancho - 1, (cam + motor.anchoVista).ceil() + 1);
    final tierra = Paint()..color = tema.tierra;
    final cesped = Paint()..color = tema.cesped;
    final ladrillo = Paint()..color = tema.ladrillo;
    final junta = Paint()
      ..color = Color.lerp(tema.ladrillo, Colors.black, 0.3)!
      ..strokeWidth = max(1, s * 0.05);
    final manchas = Paint()..color = Color.lerp(tema.tierra, Colors.black, 0.12)!;
    final liquido = Paint()..color = tema.liquido ?? Colors.blue;
    final liquidoClaro = Paint()
      ..color = Color.lerp(tema.liquido ?? Colors.blue, Colors.white, 0.35)!;
    final pincho = Paint()..color = const Color(0xFFB8BCC8);
    final pinchoOscuro = Paint()..color = const Color(0xFF6E7380);
    final oro = Paint()..color = const Color(0xFFFFC93C);
    final oroOscuro = Paint()..color = const Color(0xFFE09A1A);

    // Mientras Paco no entra, el pasillo secreto (pescados y portal incluidos)
    // se ve como tierra normal
    final secreto = motor.nivel.caminoSecreto;
    final dentro = motor.paco.x < anchoSecreto + 0.5;
    for (var x = x0; x <= x1; x++) {
      for (var y = 0; y < Mapa.alto; y++) {
        var cas = m.casillas[x][y];
        if (secreto && x < anchoSecreto && cas != Casilla.vacio &&
            !esSolida(cas) && !dentro) {
          cas = Casilla.falso;
        }
        if (cas == Casilla.vacio) continue;
        final r = Rect.fromLTWH(x * s, y * s, s + 0.6, s + 0.6);
        switch (cas) {
          case Casilla.tierra:
            c.drawRect(r, tierra);
            if ((x * 7 + y * 3) % 5 == 0) {
              c.drawCircle(r.center + Offset(s * 0.15, s * 0.1), s * 0.1, manchas);
            }
            if (!esSolida(m.en(x, y - 1))) {
              c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, s * 0.32), cesped);
            }
          case Casilla.ladrillo when tema.decorado == Decorado.corales:
            _coral(c, r, s, x, y);
          case Casilla.ladrillo:
            c.drawRect(r, ladrillo);
            c.drawLine(Offset(r.left, r.top + s / 2), Offset(r.right, r.top + s / 2), junta);
            c.drawLine(Offset(r.left, r.top), Offset(r.right, r.top), junta);
            final mx = (y.isEven ? 0.5 : 0.0) * s;
            c.drawLine(Offset(r.left + mx + 0.01, r.top), Offset(r.left + mx + 0.01, r.top + s / 2), junta);
            c.drawLine(Offset(r.left + s / 2 - mx, r.top + s / 2), Offset(r.left + s / 2 - mx, r.bottom), junta);
          case Casilla.liquido:
            if (m.en(x, y - 1) != Casilla.liquido) {
              final ola = sin(motor.t * 3 + x * 0.9) * s * 0.08;
              c.drawRect(Rect.fromLTRB(r.left, r.top + s * 0.25 + ola, r.right, r.bottom), liquido);
              c.drawRect(Rect.fromLTWH(r.left, r.top + s * 0.25 + ola, r.width, s * 0.12), liquidoClaro);
            } else {
              c.drawRect(r, liquido);
            }
          case Casilla.pinchos:
            for (var k = 0; k < 3; k++) {
              final px = r.left + k * s / 3;
              final path = Path()
                ..moveTo(px, r.bottom)
                ..lineTo(px + s / 6, r.top + s * 0.4)
                ..lineTo(px + s / 3, r.bottom)
                ..close();
              c.drawPath(path, k == 1 ? pincho : pinchoOscuro);
            }
          case Casilla.moneda:
            final flota = sin(motor.t * 4 + x) * s * 0.06;
            _pescado(c, r.center + Offset(0, flota), s * 0.38, oro, oroOscuro);
          case Casilla.corazon:
            final late = 1 + sin(motor.t * 6) * 0.08;
            _corazon(c, r.center, s * 0.35 * late, Paint()..color = const Color(0xFFFF4D6D));
          case Casilla.falso:
            // Pared falsa: se ve como tierra, pero se aclara al entrar
            c.drawRect(r, Paint()..color = tema.tierra.withValues(alpha: dentro ? 0.3 : 1));
            if (!dentro && (x * 7 + y * 3) % 5 == 0) {
              c.drawCircle(r.center + Offset(s * 0.15, s * 0.1), s * 0.1, manchas);
            }
          case Casilla.portal:
            if (m.en(x, y + 1) == Casilla.portal) {
              final centro = Offset(r.center.dx, r.bottom);
              final giro = motor.t * 2;
              for (var k = 3; k >= 1; k--) {
                c.drawOval(Rect.fromCenter(center: centro, width: s * 0.5 * k, height: s * 0.85 * k),
                    Paint()
                      ..color = HSVColor.fromAHSV(1, (giro * 60 + k * 70) % 360, 0.7, 1).toColor());
              }
            }
          case Casilla.vacio:
            break;
        }
      }
    }
  }

  void _pescado(Canvas c, Offset o, double t, Paint cuerpo, Paint borde) {
    c.drawOval(Rect.fromCenter(center: o, width: t * 1.6, height: t), cuerpo);
    final cola = Path()
      ..moveTo(o.dx + t * 0.6, o.dy)
      ..lineTo(o.dx + t * 1.1, o.dy - t * 0.45)
      ..lineTo(o.dx + t * 1.1, o.dy + t * 0.45)
      ..close();
    c.drawPath(cola, borde);
    c.drawCircle(o + Offset(-t * 0.4, -t * 0.1), t * 0.12, Paint()..color = Colors.black87);
  }

  void _corazon(Canvas c, Offset o, double t, Paint p) {
    final path = Path()
      ..moveTo(o.dx, o.dy + t)
      ..cubicTo(o.dx - t * 1.6, o.dy - t * 0.2, o.dx - t * 0.6, o.dy - t * 1.2, o.dx, o.dy - t * 0.4)
      ..cubicTo(o.dx + t * 0.6, o.dy - t * 1.2, o.dx + t * 1.6, o.dy - t * 0.2, o.dx, o.dy + t)
      ..close();
    c.drawPath(path, p);
  }

  void _banderas(Canvas c, double s) {
    final m = motor.mapa;
    final palo = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = s * 0.12;
    if (m.controlX > 0) {
      final x = m.controlX * s + s * 0.5;
      final suelo = (m.controlY ?? m.suelo(m.controlX.floor())) * s;
      c.drawLine(Offset(x, suelo), Offset(x, suelo - s * 2.2), palo);
      final color = motor.control ? const Color(0xFF4CD964) : const Color(0xFFB0B0B0);
      final ondea = sin(motor.t * 5) * s * 0.1;
      final b = Path()
        ..moveTo(x, suelo - s * 2.2)
        ..lineTo(x + s * 1.0, suelo - s * 1.9 + ondea)
        ..lineTo(x, suelo - s * 1.6)
        ..close();
      c.drawPath(b, Paint()..color = color);
    }
    if (motor.jefe == null) {
      final x = m.metaX * s + s * 0.5;
      final suelo = (m.metaY ?? m.suelo(m.metaX.floor())) * s;
      c.drawLine(Offset(x, suelo), Offset(x, suelo - s * 6), palo);
      c.drawCircle(Offset(x, suelo - s * 6), s * 0.22, Paint()..color = const Color(0xFFFFC93C));
      final ondea = sin(motor.t * 5) * s * 0.15;
      final b = Path()
        ..moveTo(x, suelo - s * 5.7)
        ..quadraticBezierTo(x + s, suelo - s * 5.5 + ondea, x + s * 2, suelo - s * 5.2 + ondea)
        ..lineTo(x, suelo - s * 4.4)
        ..close();
      c.drawPath(b, Paint()..color = const Color(0xFFFF8A1F));
      _pescado(c, Offset(x + s * 0.7, suelo - s * 5.2), s * 0.3,
          Paint()..color = Colors.white, Paint()..color = Colors.white70);
    }
  }

  /// Detalles de los trajes de premio: llamas, burbujas de ácido, brillos
  /// o sombrero de hongo.
  void _adorno(Canvas c, double u, Adorno a, Offset cab, Offset puntaCola) {
    final t = motor.t;
    switch (a) {
      case Adorno.ninguno:
        break;
      case Adorno.llamas:
        for (final (base, tam) in [(cab + Offset(0, -u * 0.26), 1.0), (puntaCola, 0.7)]) {
          for (var k = 0; k < 3; k++) {
            final alto = u * (0.22 + sin(t * 14 + k * 2) * 0.06) * tam;
            final x = base.dx + (k - 1) * u * 0.1 * tam;
            c.drawPath(
                Path()
                  ..moveTo(x - u * 0.07 * tam, base.dy)
                  ..quadraticBezierTo(x - u * 0.05 * tam, base.dy - alto * 0.6, x, base.dy - alto)
                  ..quadraticBezierTo(x + u * 0.05 * tam, base.dy - alto * 0.6, x + u * 0.07 * tam, base.dy)
                  ..close(),
                Paint()..color = k == 1 ? const Color(0xFFFFD23F) : const Color(0xFFFF7A1A));
          }
        }
      case Adorno.acido:
        final burbuja = Paint()..color = const Color(0xCC8BE03A);
        for (var k = 0; k < 3; k++) {
          final f = (t * 0.9 + k / 3) % 1.0;
          c.drawCircle(cab + Offset(-u * 0.3 + k * u * 0.25, -u * 0.3 - f * u * 0.7),
              u * (0.05 + 0.03 * (1 - f)), burbuja);
        }
        c.drawCircle(puntaCola, u * 0.08, Paint()..color = const Color(0xFF8BE03A));
      case Adorno.brillo:
        final brillo = Paint()..color = Colors.white;
        for (var k = 0; k < 3; k++) {
          final f = (t * 1.3 + k * 0.37) % 1.0;
          final tam = sin(f * pi) * u * 0.09;
          final o = Offset(-u * 0.45 + k * u * 0.45, -u * 1.05 + (k.isEven ? 0 : u * 0.25));
          c.drawPath(
              Path()
                ..moveTo(o.dx, o.dy - tam * 2)
                ..lineTo(o.dx + tam * 0.5, o.dy)
                ..lineTo(o.dx, o.dy + tam * 2)
                ..lineTo(o.dx - tam * 0.5, o.dy)
                ..close()
                ..moveTo(o.dx - tam * 2, o.dy)
                ..lineTo(o.dx, o.dy - tam * 0.5)
                ..lineTo(o.dx + tam * 2, o.dy)
                ..lineTo(o.dx, o.dy + tam * 0.5)
                ..close(),
              brillo);
        }
      case Adorno.hongo:
        // Sombrero de seta roja con puntos blancos
        final sombrero = Rect.fromCenter(center: cab + Offset(0, -u * 0.2), width: u * 0.8, height: u * 0.5);
        c.drawArc(sombrero, pi, pi, true, Paint()..color = const Color(0xFFE23B3B));
        final punto = Paint()..color = Colors.white;
        c.drawCircle(cab + Offset(-u * 0.18, -u * 0.32), u * 0.06, punto);
        c.drawCircle(cab + Offset(u * 0.06, -u * 0.38), u * 0.07, punto);
        c.drawCircle(cab + Offset(u * 0.24, -u * 0.27), u * 0.05, punto);
    }
  }

  /// Ala de plumas que sale del hombro y gira (ángulo en radianes, 0 = hacia atrás).
  void _alaPerro(Canvas c, double s, Offset hombro, double angulo, Color color) {
    c.save();
    c.translate(hombro.dx, hombro.dy);
    c.rotate(angulo);
    final ala = Path()
      ..moveTo(0, -s * 0.06)
      ..quadraticBezierTo(-s * 0.3, -s * 0.22, -s * 0.62, -s * 0.12)
      ..lineTo(-s * 0.5, -s * 0.03)
      ..lineTo(-s * 0.56, s * 0.03)
      ..lineTo(-s * 0.4, s * 0.06)
      ..lineTo(-s * 0.42, s * 0.12)
      ..quadraticBezierTo(-s * 0.18, s * 0.12, 0, s * 0.06)
      ..close();
    c.drawPath(ala, Paint()..color = color);
    c.drawPath(
        ala,
        Paint()
          ..color = const Color(0x33000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03);
    c.restore();
  }

  // ------------------------------------------------------------- personajes
  void _paco(Canvas c, double s) {
    final p = motor.paco;
    if (motor.invencible > 0 && (motor.t * 12).floor().isEven &&
        motor.estado == Estado.jugando) {
      return;
    }
    final muerto = motor.estado == Estado.muerto;
    final dir = motor.dirPaco.toDouble();
    c.save();
    c.translate((p.x + p.w / 2) * s, (p.y + p.h) * s);
    if (muerto) {
      c.translate(0, -p.h * s / 2);
      c.rotate(pi);
      c.translate(0, p.h * s / 2);
    }
    c.scale(dir, 1);
    final u = s; // una casilla
    final skin = Progreso.skin;
    final naranja = Paint()..color = skin.cuerpo;
    final oscuro = Paint()..color = skin.oscuro;
    final crema = Paint()..color = skin.crema;
    final negro = Paint()..color = const Color(0xFF1F2A3A);
    final ojos = Paint()..color = skin.ojos;

    final enAire = !p.enSuelo && !motor.enAgua;
    final paso = motor.pasos * 2.2;
    final pata = enAire ? 0.12 : sin(paso) * 0.12;

    // Cola
    final cola = Path()
      ..moveTo(-u * 0.32, -u * 0.35)
      ..quadraticBezierTo(-u * 0.75, -u * 0.5 + sin(motor.t * 4) * u * 0.08,
          -u * 0.6, -u * 0.95);
    c.drawPath(
        cola,
        Paint()
          ..color = skin.oscuro
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.14
          ..strokeCap = StrokeCap.round);
    // Patas
    for (final k in [-1.0, 1.0]) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(-u * 0.25 + k * u * 0.15 + pata * k * u, -u * 0.25,
                  u * 0.16, u * 0.25),
              Radius.circular(u * 0.07)),
          k > 0 && !skin.puntas ? naranja : oscuro);
    }
    // Cuerpo
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-u * 0.38, -u * 0.62, u * 0.7, u * 0.42),
            Radius.circular(u * 0.2)),
        naranja);
    c.drawOval(Rect.fromLTWH(-u * 0.12, -u * 0.48, u * 0.36, u * 0.26), crema);
    // Rayas
    final raya = Paint()
      ..color = skin.puntas ? skin.cuerpo : skin.oscuro
      ..strokeWidth = u * 0.05
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(-u * 0.25, -u * 0.6), Offset(-u * 0.22, -u * 0.48), raya);
    c.drawLine(Offset(-u * 0.12, -u * 0.62), Offset(-u * 0.1, -u * 0.5), raya);
    // Cabeza
    final cab = Offset(u * 0.22, -u * 0.72);
    final orejaI = Path()
      ..moveTo(cab.dx - u * 0.25, cab.dy - u * 0.08)
      ..lineTo(cab.dx - u * 0.2, cab.dy - u * 0.42)
      ..lineTo(cab.dx - u * 0.02, cab.dy - u * 0.2)
      ..close();
    final orejaD = Path()
      ..moveTo(cab.dx + u * 0.05, cab.dy - u * 0.2)
      ..lineTo(cab.dx + u * 0.22, cab.dy - u * 0.42)
      ..lineTo(cab.dx + u * 0.27, cab.dy - u * 0.08)
      ..close();
    c.drawPath(orejaI, oscuro);
    c.drawPath(orejaD, skin.puntas ? oscuro : naranja);
    c.drawCircle(cab, u * 0.28, naranja);
    if (skin.puntas) {
      // Máscara oscura de los siameses
      c.drawOval(Rect.fromCenter(center: cab + Offset(u * 0.1, u * 0.04), width: u * 0.38, height: u * 0.36), oscuro);
    }
    c.drawOval(Rect.fromCenter(center: cab + Offset(u * 0.12, u * 0.1), width: u * 0.3, height: u * 0.2),
        skin.puntas ? oscuro : crema);
    if (muerto) {
      final x = Paint()
        ..color = negro.color
        ..strokeWidth = u * 0.05;
      final o = cab + Offset(u * 0.12, -u * 0.05);
      c.drawLine(o - Offset(u * 0.06, u * 0.06), o + Offset(u * 0.06, u * 0.06), x);
      c.drawLine(o + Offset(-u * 0.06, u * 0.06), o + Offset(u * 0.06, -u * 0.06), x);
    } else {
      c.drawOval(Rect.fromCenter(center: cab + Offset(u * 0.12, -u * 0.05), width: u * 0.11, height: u * 0.15), ojos);
      c.drawOval(Rect.fromCenter(center: cab + Offset(u * 0.125, -u * 0.05), width: u * 0.04, height: u * 0.12), negro);
      c.drawCircle(cab + Offset(u * 0.135, -u * 0.08), u * 0.025, Paint()..color = Colors.white);
    }
    c.drawCircle(cab + Offset(u * 0.27, u * 0.06), u * 0.04, Paint()..color = const Color(0xFFE0607E));
    final bigote = Paint()
      ..color = negro.color
      ..strokeWidth = u * 0.02;
    c.drawLine(cab + Offset(u * 0.22, u * 0.12), cab + Offset(u * 0.42, u * 0.08), bigote);
    c.drawLine(cab + Offset(u * 0.22, u * 0.14), cab + Offset(u * 0.42, u * 0.18), bigote);
    _adorno(c, u, skin.adorno, cab, Offset(-u * 0.6, -u * 0.95));
    if (motor.enAgua) {
      // A Paco no le gusta mojarse: casco de buzo
      c.drawCircle(cab + Offset(u * 0.03, -u * 0.04), u * 0.42,
          Paint()..color = const Color(0x55BFEFFF));
      c.drawCircle(
          cab + Offset(u * 0.03, -u * 0.04),
          u * 0.42,
          Paint()
            ..color = const Color(0xFFD9A93A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.06);
      c.drawArc(Rect.fromCircle(center: cab + Offset(u * 0.03, -u * 0.04), radius: u * 0.32),
          -2.4, 0.9, false,
          Paint()
            ..color = Colors.white70
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.04
            ..strokeCap = StrokeCap.round);
      final burbuja = Paint()
        ..color = Colors.white60
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.025;
      final fase = (motor.t * 1.5) % 1.0;
      c.drawCircle(cab + Offset(u * 0.35, -u * 0.5 - fase * u * 0.8), u * 0.07, burbuja);
    }
    c.restore();
  }

  void _perro(Canvas c, double u, Color color, {double paso = 0, bool enfadado = true}) {
    // Dibujado mirando a la derecha con los pies en (0,0).
    final cuerpo = Paint()..color = color;
    final oscuro = Paint()..color = Color.lerp(color, Colors.black, 0.3)!;
    final hocico = Paint()..color = Color.lerp(color, Colors.white, 0.45)!;
    final negro = Paint()..color = const Color(0xFF1F1A22);
    final pata = sin(paso) * 0.1;
    // Cola
    c.drawLine(Offset(-u * 0.4, -u * 0.5), Offset(-u * 0.6, -u * 0.8 + sin(paso * 2) * u * 0.05),
        Paint()
          ..color = oscuro.color
          ..strokeWidth = u * 0.1
          ..strokeCap = StrokeCap.round);
    for (final k in [-1.0, 1.0]) {
      c.drawRect(Rect.fromLTWH(-u * 0.3 + k * u * 0.15 + pata * k * u, -u * 0.25, u * 0.14, u * 0.25), oscuro);
      c.drawRect(Rect.fromLTWH(u * 0.1 + k * u * 0.12 - pata * k * u, -u * 0.25, u * 0.14, u * 0.25), oscuro);
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-u * 0.45, -u * 0.62, u * 0.8, u * 0.4), Radius.circular(u * 0.18)), cuerpo);
    final cab = Offset(u * 0.32, -u * 0.62);
    c.drawCircle(cab, u * 0.26, cuerpo);
    c.drawOval(Rect.fromCenter(center: cab + Offset(u * 0.2, u * 0.08), width: u * 0.3, height: u * 0.2), hocico);
    c.drawCircle(cab + Offset(u * 0.34, u * 0.04), u * 0.06, negro);
    // Oreja caída
    c.drawOval(Rect.fromCenter(center: cab + Offset(-u * 0.14, u * 0.02), width: u * 0.16, height: u * 0.36), oscuro);
    c.drawCircle(cab + Offset(u * 0.08, -u * 0.06), u * 0.05, negro);
    if (enfadado) {
      c.drawLine(cab + Offset(u * 0.0, -u * 0.16), cab + Offset(u * 0.16, -u * 0.1),
          Paint()
            ..color = negro.color
            ..strokeWidth = u * 0.04);
    }
  }

  void _enemigo(Canvas c, double s, Enemigo e) {
    if (!e.vivo && (e.tipo == TipoEnemigo.fuego || e.aplastado > 0.5)) return;
    if (e.x + e.w < motor.camX - 2 || e.x > motor.camX + motor.anchoVista + 2) return;
    c.save();
    c.translate((e.x + e.w / 2) * s, (e.y + e.h) * s);
    if (!e.vivo) {
      c.scale(1, 0.35);
    }
    c.scale(e.dir.toDouble() * e.tamano, e.tamano);
    // Aviso antes de lanzar: brilla del color de lo que va a lanzar
    final aviso = e.aviso > 0 && e.vivo
        ? switch (e.tipo) {
            TipoEnemigo.hielo || TipoEnemigo.pezHielo => const Color(0xFF7FE0FF),
            TipoEnemigo.llamas => const Color(0xFFFF7A1A),
            TipoEnemigo.acido => const Color(0xFF8BE03A),
            _ => const Color(0xFFFF3B3B),
          }
        : null;
    final pulso = 0.55 + sin(motor.t * 22) * 0.25;
    if (aviso != null) {
      c.drawCircle(Offset(0, -s * 0.5), s * 0.75,
          Paint()
            ..color = aviso.withValues(alpha: pulso * 0.7)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.15));
      c.saveLayer(null, Paint());
    }
    switch (e.tipo) {
      case TipoEnemigo.perro:
        _perro(c, s, const Color(0xFFA0703F), paso: e.t * 10);
      case TipoEnemigo.saltarin:
        _perro(c, s, const Color(0xFF6E5A8A), paso: e.t * 12);
      case TipoEnemigo.hielo:
        _perro(c, s, const Color(0xFF8FD0F0), paso: e.t * 8);
        c.drawPath(
            Path()
              ..moveTo(s * 0.22, -s * 0.85)
              ..lineTo(s * 0.3, -s * 1.12)
              ..lineTo(s * 0.38, -s * 0.85)
              ..close(),
            Paint()..color = const Color(0xFFE8FAFF));
      case TipoEnemigo.llamas:
        _perro(c, s, const Color(0xFFD94A2A), paso: e.t * 8);
        final alto = s * (0.25 + sin(e.t * 14) * 0.05);
        c.drawPath(
            Path()
              ..moveTo(s * 0.2, -s * 0.84)
              ..lineTo(s * 0.3, -s * 0.84 - alto)
              ..lineTo(s * 0.42, -s * 0.84)
              ..close(),
            Paint()..color = const Color(0xFFFFB020));
      case TipoEnemigo.acido:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-s * 0.4, -s * 0.95, s * 0.3, s * 0.4), Radius.circular(s * 0.08)),
            Paint()..color = const Color(0xFF8BE03A));
        _perro(c, s, const Color(0xFF6A7A5A), paso: e.t * 8);
        c.drawCircle(Offset(s * 0.58, -s * 0.56), s * 0.06, Paint()..color = const Color(0xFF8BE03A));
      case TipoEnemigo.espinoso:
        final infla = e.inflar > 0 ? 1 + e.inflar * 0.6 : 1.0;
        c.scale(infla, infla);
        final destello = e.inflar > 0 && (e.inflar * 12).floor().isEven;
        final espina = Paint()..color = const Color(0xFFF2A33A);
        for (var k = 0; k < 5; k++) {
          final x = -s * 0.4 + k * s * 0.17;
          c.drawPath(
              Path()
                ..moveTo(x - s * 0.07, -s * 0.6)
                ..lineTo(x, -s * 0.82)
                ..lineTo(x + s * 0.07, -s * 0.6)
                ..close(),
              espina);
        }
        _perro(c, s, destello ? const Color(0xFFFF6B6B) : const Color(0xFF2FA89A), paso: e.t * 8);
      case TipoEnemigo.robot:
        _perroRobot(c, s, e);
      case TipoEnemigo.volador:
        // Las alas giran desde el hombro: el ala de atrás va detrás del perro
        final aleteo = sin(e.t * 14);
        final hombro = Offset(s * 0.02, -s * 0.56);
        _alaPerro(c, s * 1.15, hombro.translate(s * 0.06, -s * 0.02),
            0.65 + sin(e.t * 14 - 0.4) * 0.8, const Color(0xFFC9D3E0));
        _perro(c, s * 0.9, const Color(0xFFD9C27A), paso: 0);
        _alaPerro(c, s * 1.15, hombro, 0.55 + aleteo * 0.85, Colors.white);
      case TipoEnemigo.pez:
        _pez(c, s, e, const Color(0xFFFF8A65), const Color(0xFFE0603A));
      case TipoEnemigo.pezHielo:
        _pez(c, s, e, const Color(0xFF8FD8F5), const Color(0xFF3FA4D8));
        // Cresta de hielo
        for (var k = 0; k < 3; k++) {
          final x = -s * 0.15 + k * s * 0.15;
          c.drawPath(
              Path()
                ..moveTo(x - s * 0.06, -s * 0.6)
                ..lineTo(x, -s * 0.82)
                ..lineTo(x + s * 0.06, -s * 0.6)
                ..close(),
              Paint()..color = const Color(0xFFE8FAFF));
        }
      case TipoEnemigo.pezMorado:
        _pez(c, s, e, const Color(0xFF9B5DE5), const Color(0xFF6A2FB0), enfadado: true);
      case TipoEnemigo.pezGlobo:
        // Redondo con púas; se hincha y parpadea antes de explotar
        final infla = e.inflar > 0 ? 1 + e.inflar * 0.7 : 1.0;
        final destello = e.inflar > 0 && (e.inflar * 14).floor().isEven;
        final r = s * 0.34 * infla;
        final centro = Offset(0, -s * 0.36);
        final puas = Paint()..color = const Color(0xFF8A6A2A);
        for (var k = 0; k < 10; k++) {
          final a = k * pi / 5;
          final dir = Offset(cos(a), sin(a));
          c.drawPath(
              Path()
                ..moveTo(centro.dx + dir.dx * r * 0.9 - dir.dy * r * 0.15, centro.dy + dir.dy * r * 0.9 + dir.dx * r * 0.15)
                ..lineTo(centro.dx + dir.dx * r * 1.35, centro.dy + dir.dy * r * 1.35)
                ..lineTo(centro.dx + dir.dx * r * 0.9 + dir.dy * r * 0.15, centro.dy + dir.dy * r * 0.9 - dir.dx * r * 0.15)
                ..close(),
              puas);
        }
        final cola = Path()
          ..moveTo(-r * 0.9, centro.dy)
          ..lineTo(-r * 1.4, centro.dy - r * 0.45)
          ..lineTo(-r * 1.4, centro.dy + r * 0.45)
          ..close();
        c.drawPath(cola, Paint()..color = const Color(0xFFE0B040));
        c.drawCircle(centro, r, Paint()..color = destello ? const Color(0xFFFF6B6B) : const Color(0xFFF5D06A));
        c.drawOval(Rect.fromCenter(center: centro + Offset(0, r * 0.4), width: r * 1.3, height: r * 0.8),
            Paint()..color = const Color(0xFFFFF1C4));
        c.drawCircle(centro + Offset(r * 0.45, -r * 0.2), r * 0.16, Paint()..color = Colors.black);
        c.drawCircle(centro + Offset(r * 0.85, r * 0.15), r * 0.1, Paint()..color = const Color(0xFF8A4A2A));
      case TipoEnemigo.fuego:
        final r = s * 0.38;
        c.drawCircle(Offset(0, -r), r * 1.25, Paint()..color = const Color(0x66FF7A1A));
        c.drawCircle(Offset(0, -r), r, Paint()..color = const Color(0xFFFF6A1A));
        c.drawCircle(Offset(0, -r * 1.1), r * 0.6, Paint()..color = const Color(0xFFFFD23F));
    }
    if (aviso != null) {
      c.drawPaint(Paint()
        ..color = aviso.withValues(alpha: pulso * 0.55)
        ..blendMode = BlendMode.srcATop);
      c.restore();
    }
    c.restore();
  }

  /// Pez que nada; el morado tiene cara de enfadado y dientes.
  void _pez(Canvas c, double s, Enemigo e, Color color, Color oscuro, {bool enfadado = false}) {
    final cuerpo = Paint()..color = color;
    final aleta = Paint()..color = oscuro;
    c.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.33), width: s * 0.95, height: s * 0.6), cuerpo);
    final cola = Path()
      ..moveTo(-s * 0.4, -s * 0.33)
      ..lineTo(-s * 0.7, -s * 0.6 + sin(e.t * 8) * s * 0.05)
      ..lineTo(-s * 0.7, -s * 0.06 - sin(e.t * 8) * s * 0.05)
      ..close();
    c.drawPath(cola, aleta);
    c.drawOval(Rect.fromCenter(center: Offset(s * 0.12, -s * 0.48), width: s * 0.14, height: s * 0.3), aleta);
    c.drawCircle(Offset(s * 0.25, -s * 0.4), s * 0.06, Paint()..color = enfadado ? const Color(0xFFFFE14A) : Colors.black);
    final ceja = Paint()
      ..color = Colors.black
      ..strokeWidth = s * 0.04;
    if (enfadado) {
      c.drawLine(Offset(s * 0.15, -s * 0.54), Offset(s * 0.33, -s * 0.44), ceja);
      final dientes = Paint()..color = Colors.white;
      for (var k = 0; k < 3; k++) {
        final x = s * 0.22 + k * s * 0.07;
        c.drawPath(
            Path()
              ..moveTo(x, -s * 0.24)
              ..lineTo(x + s * 0.035, -s * 0.16)
              ..lineTo(x + s * 0.07, -s * 0.24)
              ..close(),
            dientes);
      }
    } else {
      c.drawLine(Offset(s * 0.18, -s * 0.52), Offset(s * 0.32, -s * 0.48), ceja);
    }
  }

  /// Perro robot: cuerpo metálico, antena y un lanzabombas en la espalda.
  void _perroRobot(Canvas c, double s, Enemigo e) {
    final metal = Paint()..color = const Color(0xFF9AA6B8);
    final oscuro = Paint()..color = const Color(0xFF5C6678);
    final pata = sin(e.t * 8) * 0.08;
    for (final k in [-1.0, 1.0]) {
      c.drawRect(Rect.fromLTWH(-s * 0.3 + k * s * 0.15 + pata * k * s, -s * 0.25, s * 0.12, s * 0.25), oscuro);
      c.drawRect(Rect.fromLTWH(s * 0.1 + k * s * 0.12 - pata * k * s, -s * 0.25, s * 0.12, s * 0.25), oscuro);
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-s * 0.45, -s * 0.62, s * 0.8, s * 0.4), Radius.circular(s * 0.06)), metal);
    // Remaches
    for (var k = 0; k < 3; k++) {
      c.drawCircle(Offset(-s * 0.32 + k * s * 0.25, -s * 0.42), s * 0.035, oscuro);
    }
    // Lanzabombas
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-s * 0.35, -s * 0.86, s * 0.34, s * 0.26), Radius.circular(s * 0.05)), oscuro);
    c.drawCircle(Offset(-s * 0.18, -s * 0.86), s * 0.1, Paint()..color = const Color(0xFF2B2F3A));
    // Cabeza cuadrada con visor
    final cab = Rect.fromLTWH(s * 0.12, -s * 0.9, s * 0.42, s * 0.4);
    c.drawRRect(RRect.fromRectAndRadius(cab, Radius.circular(s * 0.06)), metal);
    c.drawRect(Rect.fromLTWH(s * 0.26, -s * 0.8, s * 0.26, s * 0.1), Paint()..color = const Color(0xFF1F2A3A));
    final ojo = (e.t * 3).floor().isEven ? const Color(0xFFFF3B3B) : const Color(0xFFFF8A8A);
    c.drawCircle(Offset(s * 0.44, -s * 0.75), s * 0.04, Paint()..color = ojo);
    // Antena
    c.drawLine(Offset(s * 0.22, -s * 0.9), Offset(s * 0.18, -s * 1.08),
        Paint()
          ..color = oscuro.color
          ..strokeWidth = s * 0.04);
    c.drawCircle(Offset(s * 0.18, -s * 1.1), s * 0.05, Paint()..color = ojo);
  }

  void _jefe(Canvas c, double s, JefeVivo j) {
    if (j.invencible > 0 && (motor.t * 14).floor().isEven) return;
    c.save();
    c.translate((j.x + j.w / 2) * s, (j.y + j.h) * s);
    if (j.derrotado > 0) {
      c.rotate(pi);
      c.translate(0, s * 1.6 * j.datos.tamano);
    }
    if (j.modo == ModoJefe.preparando) {
      c.translate(sin(motor.t * 60) * s * 0.06, 0); // tiembla antes de embestir
    }
    c.scale(j.dir.toDouble(), 1);
    final u = s * 2 * j.datos.tamano;
    // Aviso: brilla del color del ataque que va a hacer
    final aviso = j.modo == ModoJefe.preparando
        ? const Color(0xFFFF2D2D)
        : j.aviso > 0
            ? _colorAviso(j.proximo)
            : null;
    final pulso = 0.55 + sin(motor.t * 18) * 0.25;
    if (aviso != null) {
      c.drawOval(
          Rect.fromCenter(center: Offset(0, -u * 0.4), width: u * 1.5, height: u * 1.1),
          Paint()
            ..color = aviso.withValues(alpha: pulso * 0.7)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.12));
      c.saveLayer(null, Paint());
    }
    final d = j.datos;
    final vuela = d.sabe(Habilidad.volar);
    if (d.sabe(Habilidad.jetpack)) _jetpack(c, u);
    if (d.disfraz == Disfraz.supremo) {
      // Capa roja detrás
      final capa = Path()
        ..moveTo(u * 0.1, -u * 0.62)
        ..quadraticBezierTo(-u * 0.5, -u * 0.7, -u * 0.75 + sin(motor.t * 5) * u * 0.05, -u * 0.12)
        ..lineTo(-u * 0.2, -u * 0.22)
        ..close();
      c.drawPath(capa, Paint()..color = const Color(0xFFC0182A));
    }
    if (d.disfraz == Disfraz.fuego) {
      for (var k = 0; k < 4; k++) {
        final alto = u * (0.22 + sin(motor.t * 12 + k) * 0.06);
        final x = -u * 0.35 + k * u * 0.17;
        final llama = Path()
          ..moveTo(x - u * 0.08, -u * 0.6)
          ..lineTo(x, -u * 0.6 - alto)
          ..lineTo(x + u * 0.08, -u * 0.6)
          ..close();
        c.drawPath(llama, Paint()..color = k.isEven ? const Color(0xFFFFB020) : const Color(0xFFFF5A1F));
      }
    }
    if (d.disfraz == Disfraz.yeti) {
      final pelo = Paint()..color = const Color(0xFFF7FBFF);
      for (var k = 0; k < 6; k++) {
        c.drawCircle(Offset(-u * 0.4 + k * u * 0.14, -u * 0.62), u * 0.1, pelo);
      }
    }
    _perro(c, u, d.color, paso: vuela ? 0 : motor.t * 8);
    _disfraz(c, u, d.disfraz);
    // Ojo enfadado
    c.drawCircle(Offset(u * 0.4, -u * 0.68), u * 0.03, Paint()..color = const Color(0xFFFF3A3A));
    if (j.modo == ModoJefe.mareado) {
      for (var k = 0; k < 3; k++) {
        final a = motor.t * 5 + k * 2.1;
        _estrella(c, Offset(u * 0.32 + cos(a) * u * 0.25, -u * 1.0 + sin(a) * u * 0.07), u * 0.06,
            Paint()..color = const Color(0xFFFFD23F));
      }
    }
    if (vuela && motor.enAgua) {
      final b = Paint()
        ..color = Colors.white60
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.015;
      for (var k = 0; k < 3; k++) {
        final f = (motor.t * 0.8 + k / 3) % 1.0;
        c.drawCircle(Offset(-u * 0.5, -u * 0.4 - f * u * 0.8), u * (0.03 + k * 0.01), b);
      }
    }
    if (aviso != null) {
      c.drawPaint(Paint()
        ..color = aviso.withValues(alpha: pulso * 0.6)
        ..blendMode = BlendMode.srcATop);
      c.restore();
    }
    c.restore();
  }

  Color _colorAviso(Habilidad? h) => switch (h) {
        Habilidad.disparar => const Color(0xFFFF3B3B),
        Habilidad.lluvia => const Color(0xFFB45CFF),
        Habilidad.erupcion => const Color(0xFFFFB020),
        _ => const Color(0xFFFFF04A),
      };

  void _jetpack(Canvas c, double u) {
    final metal = Paint()..color = const Color(0xFF8C96A8);
    final oscuro = Paint()..color = const Color(0xFF5A6478);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-u * 0.6, -u * 0.85, u * 0.22, u * 0.42), Radius.circular(u * 0.06)), metal);
    c.drawRect(Rect.fromLTWH(-u * 0.57, -u * 0.45, u * 0.16, u * 0.05), oscuro);
    final largo = u * (0.2 + sin(motor.t * 30) * 0.05);
    final llama = Path()
      ..moveTo(-u * 0.57, -u * 0.4)
      ..lineTo(-u * 0.49, -u * 0.4 + largo)
      ..lineTo(-u * 0.41, -u * 0.4)
      ..close();
    c.drawPath(llama, Paint()..color = const Color(0xFFFF8A1F));
    c.drawPath(
        Path()
          ..moveTo(-u * 0.54, -u * 0.4)
          ..lineTo(-u * 0.49, -u * 0.4 + largo * 0.6)
          ..lineTo(-u * 0.44, -u * 0.4)
          ..close(),
        Paint()..color = const Color(0xFFFFE066));
  }

  void _pistola(Canvas c, double u, Color color) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(u * 0.3, -u * 0.42, u * 0.42, u * 0.11), Radius.circular(u * 0.03)),
        Paint()..color = const Color(0xFFDDE3EA));
    c.drawRect(Rect.fromLTWH(u * 0.36, -u * 0.33, u * 0.08, u * 0.12), Paint()..color = const Color(0xFF5A6478));
    c.drawCircle(Offset(u * 0.73, -u * 0.365), u * 0.04, Paint()..color = color);
  }

  void _disfraz(Canvas c, double u, Disfraz d) {
    final cab = Offset(u * 0.32, -u * 0.62);
    final oro = Paint()..color = const Color(0xFFF2C94C);
    final negro = Paint()..color = const Color(0xFF1F1A22);
    final blanco = Paint()..color = const Color(0xFFF4F0E4);
    final linea = Paint()
      ..color = const Color(0xFFCFC6B0)
      ..strokeWidth = u * 0.035
      ..strokeCap = StrokeCap.round;
    switch (d) {
      case Disfraz.guardian:
        c.drawRect(Rect.fromLTWH(u * 0.08, -u * 0.5, u * 0.12, u * 0.12), Paint()..color = const Color(0xFF3A2A20));
        for (var k = 0; k < 3; k++) {
          c.drawPath(
              Path()
                ..moveTo(u * 0.08 + k * u * 0.04, -u * 0.5)
                ..lineTo(u * 0.1 + k * u * 0.04, -u * 0.56)
                ..lineTo(u * 0.12 + k * u * 0.04, -u * 0.5)
                ..close(),
              Paint()..color = const Color(0xFFB8BCC8));
        }
      case Disfraz.caballero:
        c.drawArc(Rect.fromCircle(center: cab, radius: u * 0.29), pi, pi, true, Paint()..color = const Color(0xFF9AA0B0));
        c.drawRect(Rect.fromLTWH(cab.dx + u * 0.02, cab.dy - u * 0.08, u * 0.25, u * 0.04), negro);
        c.drawLine(cab + Offset(0, -u * 0.29), cab + Offset(-u * 0.1, -u * 0.45),
            Paint()
              ..color = const Color(0xFFE0304A)
              ..strokeWidth = u * 0.06
              ..strokeCap = StrokeCap.round);
        c.drawOval(Rect.fromCenter(center: Offset(u * 0.18, -u * 0.38), width: u * 0.2, height: u * 0.3), Paint()..color = const Color(0xFF3F6BD0));
        c.drawLine(Offset(u * 0.18, -u * 0.5), Offset(u * 0.18, -u * 0.26), oro..strokeWidth = u * 0.03);
      case Disfraz.momia:
        for (var k = 0; k < 4; k++) {
          c.drawLine(Offset(-u * 0.42 + k * u * 0.2, -u * 0.6), Offset(-u * 0.32 + k * u * 0.2, -u * 0.25), linea);
        }
        c.drawLine(cab + Offset(-u * 0.2, -u * 0.12), cab + Offset(u * 0.22, -u * 0.18), linea);
        c.drawLine(cab + Offset(-u * 0.2, u * 0.06), cab + Offset(u * 0.2, u * 0.02), linea);
      case Disfraz.faraon:
        final nemes = Path()
          ..moveTo(cab.dx - u * 0.28, cab.dy - u * 0.05)
          ..lineTo(cab.dx - u * 0.38, cab.dy + u * 0.3)
          ..lineTo(cab.dx - u * 0.1, cab.dy + u * 0.3)
          ..lineTo(cab.dx - u * 0.05, cab.dy - u * 0.05)
          ..close();
        c.drawPath(nemes, oro);
        c.drawArc(Rect.fromCircle(center: cab, radius: u * 0.28), pi, pi, true, oro);
        final azul = Paint()
          ..color = const Color(0xFF2A55B8)
          ..strokeWidth = u * 0.03;
        for (var k = 0; k < 3; k++) {
          c.drawLine(cab + Offset(-u * 0.26, -u * 0.14 + k * u * 0.1), cab + Offset(u * 0.2, -u * 0.2 + k * u * 0.06), azul);
        }
        c.drawCircle(cab + Offset(u * 0.05, -u * 0.3), u * 0.05, Paint()..color = const Color(0xFF3FAF5A));
      case Disfraz.pirata:
        final sombrero = Path()
          ..moveTo(cab.dx - u * 0.35, cab.dy - u * 0.18)
          ..quadraticBezierTo(cab.dx, cab.dy - u * 0.55, cab.dx + u * 0.35, cab.dy - u * 0.18)
          ..close();
        c.drawPath(sombrero, negro);
        _calavera(c, cab + Offset(0, -u * 0.3), u * 0.05);
        c.drawCircle(Offset(u * 0.4, -u * 0.68), u * 0.06, negro);
        c.drawLine(cab + Offset(-u * 0.1, -u * 0.18), cab + Offset(u * 0.2, u * 0.0), negro..strokeWidth = u * 0.02);
      case Disfraz.buzo:
        c.drawCircle(cab, u * 0.36, Paint()..color = const Color(0x6699DDFF));
        c.drawCircle(
            cab,
            u * 0.36,
            Paint()
              ..color = const Color(0xFFD9A93A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = u * 0.06);
        c.drawCircle(cab + Offset(u * 0.36, 0), u * 0.07, Paint()..color = const Color(0xFFD9A93A));
      case Disfraz.nube:
        c.drawRect(Rect.fromLTWH(cab.dx - u * 0.05, cab.dy - u * 0.14, u * 0.3, u * 0.05), negro);
        c.drawCircle(cab + Offset(u * 0.08, -u * 0.07), u * 0.07, Paint()..color = const Color(0xFF9FD8FF));
        for (var k = 0; k < 3; k++) {
          c.drawCircle(Offset(-u * 0.3 + k * u * 0.25, -u * 0.18), u * 0.12, Paint()..color = Colors.white);
        }
      case Disfraz.trueno:
        final rayo = Path()
          ..moveTo(cab.dx, cab.dy - u * 0.2)
          ..lineTo(cab.dx - u * 0.08, cab.dy - u * 0.42)
          ..lineTo(cab.dx + u * 0.02, cab.dy - u * 0.38)
          ..lineTo(cab.dx - u * 0.03, cab.dy - u * 0.58)
          ..lineTo(cab.dx + u * 0.12, cab.dy - u * 0.32)
          ..lineTo(cab.dx + u * 0.03, cab.dy - u * 0.35)
          ..close();
        c.drawPath(rayo, Paint()..color = const Color(0xFFFFE04A));
        c.drawRect(Rect.fromLTWH(cab.dx - u * 0.05, cab.dy - u * 0.14, u * 0.3, u * 0.05), negro);
      case Disfraz.esquimal:
        c.drawCircle(cab, u * 0.33, Paint()..color = const Color(0xFF8A5A3A));
        c.drawCircle(
            cab,
            u * 0.31,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = u * 0.07);
        c.drawCircle(cab, u * 0.2, Paint()..color = const Color(0xFFF2F2F2));
        c.drawCircle(cab + Offset(u * 0.08, -u * 0.04), u * 0.03, negro);
        c.drawCircle(cab + Offset(u * 0.2, u * 0.06), u * 0.04, negro);
        c.drawRect(Rect.fromLTWH(-u * 0.45, -u * 0.62, u * 0.8, u * 0.12), Paint()..color = const Color(0xFF8A5A3A));
      case Disfraz.yeti:
        c.drawPath(
            Path()
              ..moveTo(cab.dx - u * 0.15, cab.dy - u * 0.2)
              ..lineTo(cab.dx - u * 0.1, cab.dy - u * 0.42)
              ..lineTo(cab.dx, cab.dy - u * 0.24)
              ..close(),
            Paint()..color = const Color(0xFFBFD8EA));
      case Disfraz.robot:
      case Disfraz.megaRobot:
        final metal = Paint()..color = const Color(0xFFB8C0CE);
        c.drawRect(Rect.fromLTWH(-u * 0.3, -u * 0.58, u * 0.4, u * 0.3), metal);
        for (var k = 0; k < 3; k++) {
          c.drawCircle(Offset(-u * 0.22 + k * u * 0.12, -u * 0.43), u * 0.03,
              Paint()..color = k == ((motor.t * 3).floor() % 3) ? const Color(0xFF34E0E0) : const Color(0xFF5A6478));
        }
        c.drawLine(cab + Offset(0, -u * 0.24), cab + Offset(0, -u * 0.42),
            Paint()
              ..color = const Color(0xFF5A6478)
              ..strokeWidth = u * 0.03);
        c.drawCircle(cab + Offset(0, -u * 0.44), u * 0.05, Paint()..color = const Color(0xFFFF3A3A));
        if (d == Disfraz.megaRobot) {
          c.drawRect(Rect.fromLTWH(cab.dx - u * 0.02, cab.dy - u * 0.1, u * 0.3, u * 0.07), Paint()..color = const Color(0xFFFF3A3A));
        }
        _pistola(c, u, d == Disfraz.megaRobot ? const Color(0xFFFF3A3A) : const Color(0xFF34E0E0));
      case Disfraz.fuego:
        c.drawCircle(cab + Offset(u * 0.08, -u * 0.06), u * 0.05, Paint()..color = const Color(0xFFFFE066));
      case Disfraz.volcan:
        final roca = Paint()..color = const Color(0xFF3A2A26);
        final grieta = Paint()
          ..color = const Color(0xFFFF7A1A)
          ..strokeWidth = u * 0.03;
        for (var k = 0; k < 3; k++) {
          c.drawPath(
              Path()
                ..moveTo(-u * 0.42 + k * u * 0.25, -u * 0.6)
                ..lineTo(-u * 0.32 + k * u * 0.25, -u * 0.82)
                ..lineTo(-u * 0.22 + k * u * 0.25, -u * 0.6)
                ..close(),
              roca);
        }
        c.drawLine(Offset(-u * 0.3, -u * 0.5), Offset(-u * 0.1, -u * 0.35), grieta);
        c.drawLine(Offset(0, -u * 0.55), Offset(u * 0.1, -u * 0.32), grieta);
      case Disfraz.toxico:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cab.dx + u * 0.05, cab.dy - u * 0.02, u * 0.28, u * 0.22), Radius.circular(u * 0.06)),
            Paint()..color = const Color(0xFF4A5A4A));
        c.drawCircle(cab + Offset(u * 0.3, u * 0.12), u * 0.06, Paint()..color = const Color(0xFF9AE04A));
        for (var k = 0; k < 3; k++) {
          final f = (motor.t * 0.7 + k / 3) % 1.0;
          c.drawCircle(Offset(-u * 0.2 + k * u * 0.2, -u * 0.7 - f * u * 0.5), u * 0.05 * (1 - f),
              Paint()..color = const Color(0xAA9AE04A));
        }
      case Disfraz.mutante:
        c.drawCircle(cab + Offset(-u * 0.02, -u * 0.18), u * 0.06, Paint()..color = Colors.white);
        c.drawCircle(cab + Offset(-u * 0.01, -u * 0.18), u * 0.03, negro);
        for (var k = 0; k < 4; k++) {
          c.drawCircle(Offset(-u * 0.35 + k * u * 0.18, -u * 0.48 + (k % 2) * u * 0.08), u * 0.04,
              Paint()..color = const Color(0xFF2F7A2A));
        }
      case Disfraz.maestro:
        c.drawRect(Rect.fromLTWH(cab.dx - u * 0.27, cab.dy - u * 0.16, u * 0.54, u * 0.07), Paint()..color = const Color(0xFFE0304A));
        c.drawLine(cab + Offset(-u * 0.27, -u * 0.12), cab + Offset(-u * 0.5, -u * 0.05 + sin(motor.t * 8) * u * 0.03),
            Paint()
              ..color = const Color(0xFFE0304A)
              ..strokeWidth = u * 0.04);
        c.drawRect(Rect.fromLTWH(-u * 0.45, -u * 0.42, u * 0.8, u * 0.06), negro);
      case Disfraz.granMaestro:
        final gorro = Path()
          ..moveTo(cab.dx - u * 0.3, cab.dy - u * 0.15)
          ..lineTo(cab.dx - u * 0.05 + sin(motor.t * 2) * u * 0.03, cab.dy - u * 0.75)
          ..lineTo(cab.dx + u * 0.28, cab.dy - u * 0.15)
          ..close();
        c.drawPath(gorro, Paint()..color = const Color(0xFF3A2A8A));
        _estrella(c, cab + Offset(-u * 0.02, -u * 0.38), u * 0.06, oro);
        final barba = Path()
          ..moveTo(cab.dx + u * 0.1, cab.dy + u * 0.12)
          ..lineTo(cab.dx + u * 0.3, cab.dy + u * 0.15)
          ..lineTo(cab.dx + u * 0.18, cab.dy + u * 0.48)
          ..close();
        c.drawPath(barba, blanco);
      case Disfraz.gigante:
        // Peto de trabajo con botones
        c.drawRect(Rect.fromLTWH(-u * 0.3, -u * 0.6, u * 0.5, u * 0.36), Paint()..color = const Color(0xFF3F6BD0));
        c.drawCircle(Offset(-u * 0.22, -u * 0.55), u * 0.03, oro);
        c.drawCircle(Offset(u * 0.12, -u * 0.55), u * 0.03, oro);
      case Disfraz.titan:
        final cuerno = Paint()..color = const Color(0xFFF4F0E4);
        c.drawArc(Rect.fromCircle(center: cab, radius: u * 0.29), pi, pi, true, Paint()..color = const Color(0xFF6E7380));
        c.drawPath(
            Path()
              ..moveTo(cab.dx - u * 0.2, cab.dy - u * 0.2)
              ..quadraticBezierTo(cab.dx - u * 0.45, cab.dy - u * 0.35, cab.dx - u * 0.35, cab.dy - u * 0.6)
              ..lineTo(cab.dx - u * 0.12, cab.dy - u * 0.25)
              ..close(),
            cuerno);
        c.drawPath(
            Path()
              ..moveTo(cab.dx + u * 0.12, cab.dy - u * 0.25)
              ..quadraticBezierTo(cab.dx + u * 0.4, cab.dy - u * 0.4, cab.dx + u * 0.32, cab.dy - u * 0.62)
              ..lineTo(cab.dx + u * 0.22, cab.dy - u * 0.18)
              ..close(),
            cuerno);
      case Disfraz.supremo:
        final corona = Path()
          ..moveTo(u * 0.12, -u * 0.84)
          ..lineTo(u * 0.16, -u * 1.05)
          ..lineTo(u * 0.25, -u * 0.92)
          ..lineTo(u * 0.32, -u * 1.08)
          ..lineTo(u * 0.39, -u * 0.92)
          ..lineTo(u * 0.48, -u * 1.05)
          ..lineTo(u * 0.52, -u * 0.84)
          ..close();
        c.drawPath(corona, oro);
        c.drawCircle(Offset(u * 0.32, -u * 0.9), u * 0.025, Paint()..color = const Color(0xFFE0304A));
    }
  }

  void _calavera(Canvas c, Offset o, double r) {
    c.drawCircle(o, r, Paint()..color = Colors.white);
    c.drawCircle(o + Offset(-r * 0.35, -r * 0.1), r * 0.25, Paint()..color = Colors.black);
    c.drawCircle(o + Offset(r * 0.35, -r * 0.1), r * 0.25, Paint()..color = Colors.black);
  }

  void _estrella(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final a = -pi / 2 + k * pi / 5;
      final rr = k.isEven ? r : r * 0.45;
      final pt = o + Offset(cos(a) * rr, sin(a) * rr);
      if (k == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    c.drawPath(path, p);
  }

  void _proyectil(Canvas c, double s, Proyectil p) {
    if (p.espera > 0) {
      // Aviso: el suelo brilla donde va a salir el fuego
      final brillo = 0.4 + 0.4 * sin(motor.t * 25).abs();
      c.drawOval(
          Rect.fromCenter(center: Offset(p.centroX * s, p.abajo * s), width: s * 1.1, height: s * 0.35),
          Paint()..color = const Color(0xFFFF7A1A).withValues(alpha: brillo));
      return;
    }
    c.save();
    c.translate(p.centroX * s, (p.y + p.h / 2) * s);
    final angulo = atan2(p.vy, p.vx == 0 ? 0.0001 : p.vx);
    final r = s * max(p.w, p.h) / 2;
    switch (p.tipo) {
      case TipoProyectil.hueso:
        c.rotate(p.giro);
        final b = Paint()..color = const Color(0xFFF5F0E0);
        c.drawRect(Rect.fromCenter(center: Offset.zero, width: s * 0.5, height: s * 0.12), b);
        for (final dx in [-0.25, 0.25]) {
          c.drawCircle(Offset(s * dx, -s * 0.07), s * 0.09, b);
          c.drawCircle(Offset(s * dx, s * 0.07), s * 0.09, b);
        }
      case TipoProyectil.espina:
      case TipoProyectil.espinaNieve:
        c.rotate(angulo);
        final color = p.tipo == TipoProyectil.espina ? const Color(0xFF6B8E3A) : const Color(0xFFBFEFFF);
        c.drawPath(
            Path()
              ..moveTo(r * 1.1, 0)
              ..lineTo(-r * 0.8, -r * 0.3)
              ..lineTo(-r * 0.8, r * 0.3)
              ..close(),
            Paint()..color = color);
        if (p.tipo == TipoProyectil.espina) {
          c.drawLine(Offset(-r * 0.6, 0), Offset(r * 0.6, 0),
              Paint()
                ..color = const Color(0xFFE8F0C0)
                ..strokeWidth = s * 0.03);
        }
      case TipoProyectil.vendas:
      case TipoProyectil.bala:
        c.drawCircle(Offset.zero, r * 0.8, Paint()..color = const Color(0xFF2A2A30));
        c.drawCircle(Offset(-r * 0.25, -r * 0.25), r * 0.2, Paint()..color = Colors.white38);
      case TipoProyectil.burbuja:
        c.drawCircle(
            Offset.zero,
            r,
            Paint()
              ..color = Colors.white70
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.05);
      case TipoProyectil.gota:
        final color = motor.nivel.tema.liquido ?? const Color(0xFF4FA8F0);
        c.drawPath(
            Path()
              ..moveTo(0, -r)
              ..quadraticBezierTo(r * 0.9, r * 0.2, 0, r)
              ..quadraticBezierTo(-r * 0.9, r * 0.2, 0, -r),
            Paint()..color = color);
      case TipoProyectil.rayo:
        c.drawPath(
            Path()
              ..moveTo(-r * 0.2, -r * 1.2)
              ..lineTo(r * 0.5, -r * 0.1)
              ..lineTo(0, -r * 0.1)
              ..lineTo(r * 0.3, r * 1.2)
              ..lineTo(-r * 0.5, 0)
              ..lineTo(0, 0)
              ..close(),
            Paint()..color = const Color(0xFFFFE04A));
      case TipoProyectil.bolaNieve:
        c.drawCircle(Offset.zero, r * 0.8, Paint()..color = Colors.white);
      case TipoProyectil.copo:
        c.rotate(p.giro * 0.5);
        final hielo = Paint()
          ..color = Colors.white
          ..strokeWidth = s * 0.06
          ..strokeCap = StrokeCap.round;
        for (var k = 0; k < 4; k++) {
          final a = k * pi / 4;
          c.drawLine(Offset(cos(a) * r * 1.2, sin(a) * r * 1.2), Offset(-cos(a) * r * 1.2, -sin(a) * r * 1.2), hielo);
        }
      case TipoProyectil.laser:
        final color = motor.jefe?.datos.disfraz == Disfraz.megaRobot ? const Color(0xFFFF3A3A) : const Color(0xFF34E0E0);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * p.w * 1.2, height: s * p.h * 1.6), Radius.circular(s * 0.2)),
            Paint()..color = color.withValues(alpha: 0.35));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * p.w, height: s * p.h * 0.6), Radius.circular(s * 0.1)),
            Paint()..color = Colors.white);
      case TipoProyectil.fuego:
        c.drawCircle(Offset.zero, r * 1.2, Paint()..color = const Color(0x55FF7A1A));
        c.drawCircle(Offset.zero, r * 0.9, Paint()..color = const Color(0xFFFF6A1A));
        c.drawCircle(Offset(0, -r * 0.1), r * 0.5, Paint()..color = const Color(0xFFFFD23F));
      case TipoProyectil.roca:
        c.rotate(p.giro * 0.3);
        c.drawPath(
            Path()
              ..moveTo(-r, -r * 0.3)
              ..lineTo(-r * 0.3, -r)
              ..lineTo(r * 0.8, -r * 0.6)
              ..lineTo(r, r * 0.4)
              ..lineTo(0, r)
              ..lineTo(-r * 0.8, r * 0.6)
              ..close(),
            Paint()..color = const Color(0xFF5A4A44));
      case TipoProyectil.veneno:
        final crece = 1 + (1.1 - p.dividir.clamp(0, 1.1)) * 0.3;
        c.drawCircle(Offset.zero, r * crece, Paint()..color = const Color(0xCC8BE03A));
        c.drawCircle(Offset(-r * 0.3, -r * 0.3), r * 0.25, Paint()..color = Colors.white70);
      case TipoProyectil.bomba:
        // Bomba que flota: parpadea más rápido justo antes de explotar
        final queda = p.dividir.clamp(0.0, 2.0);
        final parpadeo = (motor.t * (queda < 0.6 ? 20 : 6)).floor().isEven;
        c.drawCircle(Offset.zero, r * 1.05, Paint()..color = const Color(0xFF2B2F3A));
        c.drawCircle(Offset(-r * 0.3, -r * 0.3), r * 0.25, Paint()..color = Colors.white24);
        for (var k = 0; k < 8; k++) {
          final a = k * pi / 4;
          c.drawCircle(Offset(cos(a), sin(a)) * r * 1.05, r * 0.14, Paint()..color = const Color(0xFF5C6678));
        }
        c.drawCircle(Offset.zero, r * 0.3,
            Paint()..color = parpadeo ? const Color(0xFFFF3B3B) : const Color(0xFF7A1A1A));
      case TipoProyectil.acido:
        c.drawCircle(Offset.zero, r * 1.3, Paint()..color = const Color(0x558BE03A));
        c.drawCircle(Offset.zero, r * 0.9, Paint()..color = const Color(0xFF6BD020));
        c.drawCircle(Offset(-r * 0.3, -r * 0.3), r * 0.25, Paint()..color = Colors.white70);
      case TipoProyectil.estrella:
        c.rotate(p.giro);
        _estrella(c, Offset.zero, r * 1.1, Paint()..color = const Color(0xFFFFD23F));
      case TipoProyectil.pescado:
        c.scale(p.vx >= 0 ? -1 : 1, 1);
        _pescado(c, Offset.zero, r * 0.9, Paint()..color = const Color(0xFF7FB3D9), Paint()..color = const Color(0xFF4A86B8));
      case TipoProyectil.onda:
        final color = Color.lerp(motor.nivel.tema.cesped, Colors.white, 0.4)!;
        c.drawArc(Rect.fromCenter(center: Offset(0, s * 0.3), width: s * 0.9, height: s * 1.2), pi, pi, true,
            Paint()..color = color.withValues(alpha: 0.85));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant PintorJuego old) => old.motor != motor;
}
