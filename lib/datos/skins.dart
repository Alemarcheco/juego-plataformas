import 'package:flutter/material.dart';

/// Detalle extra que llevan los trajes de premio.
enum Adorno { ninguno, llamas, acido, brillo, hongo }

/// Un traje (color de pelo) para Paco.
class Skin {
  final String id;
  final String nombre;
  final int precio;
  final Color cuerpo;
  final Color oscuro; // orejas, rayas, cola y patas
  final Color crema; // barriga y hocico
  final Color ojos;

  /// Los siameses tienen la cara, las orejas, la cola y las patas oscuras.
  final bool puntas;

  final Adorno adorno;

  /// Los trajes de premio no se compran: se ganan con un logro.
  final String? logro;

  const Skin(this.id, this.nombre, this.precio,
      {required this.cuerpo,
      required this.oscuro,
      required this.crema,
      this.ojos = const Color(0xFF1F2A3A),
      this.puntas = false,
      this.adorno = Adorno.ninguno,
      this.logro});
}

const List<Skin> skins = [
  Skin('naranja', 'Paco naranja', 0,
      cuerpo: Color(0xFFF59A33),
      oscuro: Color(0xFFD9741A),
      crema: Color(0xFFFFE2B8)),
  Skin('gris', 'Paco gris', 100,
      cuerpo: Color(0xFF9AA0AA),
      oscuro: Color(0xFF6E7480),
      crema: Color(0xFFE4E6EA)),
  Skin('siames', 'Paco siamés', 150,
      cuerpo: Color(0xFFF2E6D0),
      oscuro: Color(0xFF5A4030),
      crema: Color(0xFFFFF6E8),
      ojos: Color(0xFF3F8CE0),
      puntas: true),
  Skin('blanco', 'Paco blanco', 200,
      cuerpo: Color(0xFFF8F8F8),
      oscuro: Color(0xFFDADDE2),
      crema: Color(0xFFFFFFFF),
      ojos: Color(0xFF3FAF5A)),
  Skin('negro', 'Paco gato negro', 300,
      cuerpo: Color(0xFF2A2A30),
      oscuro: Color(0xFF15151A),
      crema: Color(0xFF3A3A42),
      ojos: Color(0xFFF2C94C)),
  // Trajes de premio (logros)
  Skin('fuego', 'Gato de fuego', 0,
      cuerpo: Color(0xFFE8452C),
      oscuro: Color(0xFFB0241A),
      crema: Color(0xFFFFC46B),
      ojos: Color(0xFFFFE14A),
      adorno: Adorno.llamas,
      logro: 'fuego'),
  Skin('acido', 'Gato de ácido', 0,
      cuerpo: Color(0xFF7BD03A),
      oscuro: Color(0xFF3F8A1E),
      crema: Color(0xFFD8F7A8),
      ojos: Color(0xFFB04AE0),
      adorno: Adorno.acido,
      logro: 'acido'),
  Skin('dorado', 'Gato dorado', 0,
      cuerpo: Color(0xFFF5C542),
      oscuro: Color(0xFFC9921A),
      crema: Color(0xFFFFF0B8),
      ojos: Color(0xFF3F8CE0),
      adorno: Adorno.brillo,
      logro: 'campeon'),
  Skin('hongo', 'Gato hongo', 0,
      cuerpo: Color(0xFFF2E6D0),
      oscuro: Color(0xFFB08A6A),
      crema: Color(0xFFFFFFFF),
      adorno: Adorno.hongo,
      logro: 'hongo'),
];
