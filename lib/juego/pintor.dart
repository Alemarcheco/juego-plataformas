import 'dart:math';

import 'package:flutter/material.dart';

import '../datos/mundos.dart';
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
    _banderas(canvas, s);
    for (final e in motor.enemigos) {
      _enemigo(canvas, s, e);
    }
    final j = motor.jefe;
    if (j != null) _jefe(canvas, s, j);
    for (final h in motor.huesos) {
      _hueso(canvas, s, h);
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

    for (var x = x0; x <= x1; x++) {
      for (var y = 0; y < Mapa.alto; y++) {
        final cas = m.casillas[x][y];
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
      final suelo = m.superficie(m.controlX.floor()) * s;
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
      final suelo = m.superficie(m.metaX.floor()) * s;
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
    final naranja = Paint()..color = const Color(0xFFF59A33);
    final oscuro = Paint()..color = const Color(0xFFD9741A);
    final crema = Paint()..color = const Color(0xFFFFE2B8);
    final negro = Paint()..color = const Color(0xFF1F2A3A);

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
          ..color = const Color(0xFFD9741A)
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
          k > 0 ? naranja : oscuro);
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
      ..color = const Color(0xFFD9741A)
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
    c.drawPath(orejaD, naranja);
    c.drawCircle(cab, u * 0.28, naranja);
    c.drawOval(Rect.fromCenter(center: cab + Offset(u * 0.12, u * 0.1), width: u * 0.3, height: u * 0.2), crema);
    if (muerto) {
      final x = Paint()
        ..color = negro.color
        ..strokeWidth = u * 0.05;
      final o = cab + Offset(u * 0.12, -u * 0.05);
      c.drawLine(o - Offset(u * 0.06, u * 0.06), o + Offset(u * 0.06, u * 0.06), x);
      c.drawLine(o + Offset(-u * 0.06, u * 0.06), o + Offset(u * 0.06, -u * 0.06), x);
    } else {
      c.drawOval(Rect.fromCenter(center: cab + Offset(u * 0.12, -u * 0.05), width: u * 0.1, height: u * 0.14), negro);
      c.drawCircle(cab + Offset(u * 0.135, -u * 0.08), u * 0.025, Paint()..color = Colors.white);
    }
    c.drawCircle(cab + Offset(u * 0.27, u * 0.06), u * 0.04, Paint()..color = const Color(0xFFE0607E));
    final bigote = Paint()
      ..color = negro.color
      ..strokeWidth = u * 0.02;
    c.drawLine(cab + Offset(u * 0.22, u * 0.12), cab + Offset(u * 0.42, u * 0.08), bigote);
    c.drawLine(cab + Offset(u * 0.22, u * 0.14), cab + Offset(u * 0.42, u * 0.18), bigote);
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
    c.scale(e.dir.toDouble(), 1);
    switch (e.tipo) {
      case TipoEnemigo.perro:
        _perro(c, s, const Color(0xFFA0703F), paso: e.t * 10);
      case TipoEnemigo.saltarin:
        _perro(c, s, const Color(0xFF6E5A8A), paso: e.t * 12);
      case TipoEnemigo.volador:
        _perro(c, s * 0.9, const Color(0xFFD9C27A), paso: 0);
        final ala = Paint()..color = Colors.white.withValues(alpha: 0.9);
        final aleteo = sin(e.t * 20) * s * 0.25;
        c.drawOval(Rect.fromCenter(center: Offset(-s * 0.05, -s * 0.75 - aleteo), width: s * 0.5, height: s * 0.3), ala);
      case TipoEnemigo.pez:
        final cuerpo = Paint()..color = const Color(0xFFFF8A65);
        final aleta = Paint()..color = const Color(0xFFE0603A);
        c.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.33), width: s * 0.95, height: s * 0.6), cuerpo);
        final cola = Path()
          ..moveTo(-s * 0.4, -s * 0.33)
          ..lineTo(-s * 0.7, -s * 0.6 + sin(e.t * 8) * s * 0.05)
          ..lineTo(-s * 0.7, -s * 0.06 - sin(e.t * 8) * s * 0.05)
          ..close();
        c.drawPath(cola, aleta);
        c.drawOval(Rect.fromCenter(center: Offset(s * 0.12, -s * 0.48), width: s * 0.14, height: s * 0.3), aleta);
        c.drawCircle(Offset(s * 0.25, -s * 0.4), s * 0.06, Paint()..color = Colors.black);
        c.drawLine(Offset(s * 0.18, -s * 0.52), Offset(s * 0.32, -s * 0.48),
            Paint()
              ..color = Colors.black
              ..strokeWidth = s * 0.04);
      case TipoEnemigo.fuego:
        final r = s * 0.38;
        c.drawCircle(Offset(0, -r), r * 1.25, Paint()..color = const Color(0x66FF7A1A));
        c.drawCircle(Offset(0, -r), r, Paint()..color = const Color(0xFFFF6A1A));
        c.drawCircle(Offset(0, -r * 1.1), r * 0.6, Paint()..color = const Color(0xFFFFD23F));
    }
    c.restore();
  }

  void _jefe(Canvas c, double s, JefeVivo j) {
    if (j.invencible > 0 && (motor.t * 14).floor().isEven) return;
    c.save();
    c.translate((j.x + j.w / 2) * s, (j.y + j.h) * s);
    if (j.derrotado > 0) {
      c.rotate(pi);
      c.translate(0, s * 1.6);
    }
    c.scale(j.dir.toDouble(), 1);
    final u = s * 2;
    _perro(c, u, j.datos.color, paso: motor.t * 8);
    if (j.datos.corona) {
      final corona = Path()
        ..moveTo(u * 0.12, -u * 0.84)
        ..lineTo(u * 0.16, -u * 1.05)
        ..lineTo(u * 0.25, -u * 0.92)
        ..lineTo(u * 0.32, -u * 1.08)
        ..lineTo(u * 0.39, -u * 0.92)
        ..lineTo(u * 0.48, -u * 1.05)
        ..lineTo(u * 0.52, -u * 0.84)
        ..close();
      c.drawPath(corona, Paint()..color = const Color(0xFFF2C94C));
      c.drawCircle(Offset(u * 0.32, -u * 0.9), u * 0.025, Paint()..color = const Color(0xFFE0304A));
    }
    // Ojo rojo
    c.drawCircle(Offset(u * 0.4, -u * 0.68), u * 0.03, Paint()..color = const Color(0xFFFF3A3A));
    c.restore();
  }

  void _hueso(Canvas c, double s, Hueso h) {
    c.save();
    c.translate((h.x + h.w / 2) * s, (h.y + h.h / 2) * s);
    c.rotate(h.giro);
    final p = Paint()..color = const Color(0xFFF5F0E0);
    c.drawRect(Rect.fromCenter(center: Offset.zero, width: s * 0.5, height: s * 0.12), p);
    for (final dx in [-0.25, 0.25]) {
      c.drawCircle(Offset(s * dx, -s * 0.07), s * 0.09, p);
      c.drawCircle(Offset(s * dx, s * 0.07), s * 0.09, p);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant PintorJuego old) => old.motor != motor;
}
