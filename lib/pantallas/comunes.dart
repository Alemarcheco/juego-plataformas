import 'package:flutter/material.dart';

import '../datos/skins.dart';
import '../progreso.dart';

/// Cara de Paco para los menús.
class RetratoPaco extends StatelessWidget {
  final double tamano;

  /// Traje a dibujar; si no se indica, el que lleva puesto.
  final Skin? skin;
  const RetratoPaco({super.key, this.tamano = 120, this.skin});

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: Size.square(tamano), painter: _CaraPaco(skin ?? Progreso.skin));
}

class _CaraPaco extends CustomPainter {
  final Skin skin;
  _CaraPaco(this.skin);

  @override
  void paint(Canvas c, Size size) {
    final u = size.width / 80;
    Offset o(double x, double y) => Offset(x * u, y * u);
    c.drawCircle(o(40, 40), 38 * u, Paint()..color = const Color(0xFFFFE2B8));
    final oreja = Paint()..color = skin.puntas ? skin.oscuro : Color.lerp(skin.cuerpo, skin.oscuro, 0.4)!;
    c.drawPath(Path()..moveTo(18 * u, 34 * u)..lineTo(22 * u, 12 * u)..lineTo(34 * u, 26 * u)..close(), oreja);
    c.drawPath(Path()..moveTo(62 * u, 34 * u)..lineTo(58 * u, 12 * u)..lineTo(46 * u, 26 * u)..close(), oreja);
    c.drawOval(Rect.fromCenter(center: o(40, 44), width: 48 * u, height: 42 * u), Paint()..color = skin.cuerpo);
    if (skin.puntas) {
      c.drawOval(Rect.fromCenter(center: o(40, 47), width: 30 * u, height: 26 * u), Paint()..color = skin.oscuro);
    }
    final negro = Paint()..color = const Color(0xFF1F2A3A);
    final ojo = Paint()..color = skin.ojos;
    c.drawCircle(o(31, 41), 4 * u, ojo);
    c.drawCircle(o(49, 41), 4 * u, ojo);
    c.drawOval(Rect.fromCenter(center: o(31, 41), width: 2 * u, height: 6 * u), negro);
    c.drawOval(Rect.fromCenter(center: o(49, 41), width: 2 * u, height: 6 * u), negro);
    c.drawCircle(o(32.2, 39.8), 1.3 * u, Paint()..color = Colors.white);
    c.drawCircle(o(50.2, 39.8), 1.3 * u, Paint()..color = Colors.white);
    c.drawPath(Path()..moveTo(37 * u, 50 * u)..lineTo(43 * u, 50 * u)..lineTo(40 * u, 53 * u)..close(),
        Paint()..color = const Color(0xFFE0607E));
    final linea = Paint()
      ..color = skin.id == 'negro' ? const Color(0xFFBFC4CC) : const Color(0xFF1F2A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * u
      ..strokeCap = StrokeCap.round;
    c.drawPath(Path()..moveTo(40 * u, 53 * u)..quadraticBezierTo(36 * u, 58 * u, 32 * u, 55 * u), linea);
    c.drawPath(Path()..moveTo(40 * u, 53 * u)..quadraticBezierTo(44 * u, 58 * u, 48 * u, 55 * u), linea);
    for (final y in [0.0, 5.0]) {
      c.drawLine(o(14, 48 + y), o(26, 47 + y * 0.8), linea);
      c.drawLine(o(66, 48 + y), o(54, 47 + y * 0.8), linea);
    }
  }

  @override
  bool shouldRepaint(covariant _CaraPaco oldDelegate) => oldDelegate.skin != skin;
}

/// Botón grande y redondeado de los menús.
class BotonJuego extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final Color color;
  final VoidCallback onPressed;
  const BotonJuego(
      {super.key,
      required this.texto,
      this.icono,
      this.color = const Color(0xFFF59A33),
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onPressed,
      icon: icono == null ? const SizedBox.shrink() : Icon(icono, size: 26),
      label: Text(texto),
    );
  }
}
