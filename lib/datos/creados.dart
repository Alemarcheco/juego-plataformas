import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../juego/generador.dart';
import 'mundos.dart';

/// Un nivel hecho en el creador de niveles.
class NivelCreado {
  String id;
  String nombre;
  String tema;
  String musica;
  bool agua;
  int ancho;

  /// [x][y], igual que en [Mapa].
  List<List<Casilla>> casillas;
  List<Aparicion> enemigos;

  /// Casilla donde empieza Paco y donde están las banderas (la fila es
  /// la casilla vacía donde se pone; se apoyan en lo que haya debajo).
  int inicioX, inicioY;
  int? controlX, controlY;
  int metaX, metaY;

  NivelCreado({
    required this.id,
    required this.nombre,
    this.tema = 'planicie',
    this.musica = 'planicie',
    this.agua = false,
    required this.ancho,
    required this.casillas,
    required this.enemigos,
    required this.inicioX,
    required this.inicioY,
    this.controlX,
    this.controlY,
    required this.metaX,
    required this.metaY,
  });

  /// Nivel nuevo: suelo plano de punta a punta, Paco a la izquierda y la
  /// meta a la derecha.
  factory NivelCreado.nuevo(String id, String nombre) {
    const ancho = 80;
    final casillas = List.generate(
        ancho,
        (_) => List.generate(
            Mapa.alto, (y) => y >= 12 ? Casilla.tierra : Casilla.vacio));
    return NivelCreado(
      id: id,
      nombre: nombre,
      ancho: ancho,
      casillas: casillas,
      enemigos: [],
      inicioX: 2,
      inicioY: 11,
      metaX: ancho - 4,
      metaY: 11,
    );
  }

  Tema get temaElegido => Temas.todos[tema] ?? Temas.planicie;

  Nivel get nivel => Nivel(1, 1, agua ? TipoNivel.agua : TipoNivel.suelo,
      temaElegido,
      creado: nombre);

  /// Mapa para jugarlo (una copia nueva cada vez, porque se comen los pescados).
  Mapa mapa() {
    final m = Mapa(ancho);
    for (var x = 0; x < ancho; x++) {
      for (var y = 0; y < Mapa.alto; y++) {
        m.casillas[x][y] = casillas[x][y];
      }
    }
    m.enemigos.addAll(enemigos);
    m.inicioX = inicioX.toDouble();
    m.inicioY = inicioY.toDouble() + 0.1;
    m.metaX = metaX.toDouble();
    m.metaY = metaY + 1;
    if (controlX != null) {
      m.controlX = controlX!.toDouble();
      m.controlY = controlY! + 1;
    }
    return m;
  }

  /// Hace el nivel más largo o más corto (mínimo 30 casillas, máximo 300).
  void cambiarAncho(int nuevo) {
    nuevo = nuevo.clamp(30, 300);
    if (nuevo > ancho) {
      final suelo = casillas.last;
      // Las columnas nuevas siguen el suelo de la última
      casillas.addAll(List.generate(
          nuevo - ancho,
          (_) => [
                for (final c in suelo)
                  c == Casilla.tierra || c == Casilla.liquido ? c : Casilla.vacio
              ]));
    } else {
      casillas.removeRange(nuevo, ancho);
      enemigos.removeWhere((e) => e.x >= nuevo);
    }
    ancho = nuevo;
    inicioX = inicioX.clamp(0, ancho - 1);
    metaX = metaX.clamp(0, ancho - 1);
    if (controlX != null && controlX! >= ancho) controlX = controlY = null;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'nombre': nombre,
        'tema': tema,
        'musica': musica,
        'agua': agua,
        'ancho': ancho,
        // Cada columna como texto: una letra por casilla
        'casillas': [
          for (final col in casillas)
            String.fromCharCodes(col.map((c) => 97 + c.index))
        ],
        'enemigos': [
          for (final e in enemigos) [e.tipo.name, e.x, e.y]
        ],
        'inicio': [inicioX, inicioY],
        'control': controlX == null ? null : [controlX, controlY],
        'meta': [metaX, metaY],
      };

  factory NivelCreado.fromJson(Map<String, dynamic> j) {
    final inicio = (j['inicio'] as List).cast<int>();
    final meta = (j['meta'] as List).cast<int>();
    final control = (j['control'] as List?)?.cast<int>();
    return NivelCreado(
      id: j['id'] as String,
      nombre: j['nombre'] as String,
      tema: j['tema'] as String? ?? 'planicie',
      musica: j['musica'] as String? ?? 'planicie',
      agua: j['agua'] as bool? ?? false,
      ancho: j['ancho'] as int,
      casillas: [
        for (final col in (j['casillas'] as List).cast<String>())
          [
            for (final c in col.codeUnits)
              Casilla.values[(c - 97).clamp(0, Casilla.values.length - 1)]
          ]
      ],
      enemigos: [
        for (final e in (j['enemigos'] as List).cast<List>())
          if (TipoEnemigo.values.any((t) => t.name == e[0]))
            Aparicion(TipoEnemigo.values.byName(e[0] as String),
                (e[1] as num).toDouble(), (e[2] as num).toDouble())
      ],
      inicioX: inicio[0],
      inicioY: inicio[1],
      controlX: control?[0],
      controlY: control?[1],
      metaX: meta[0],
      metaY: meta[1],
    );
  }
}

/// Los niveles creados se guardan en el teléfono.
class NivelesCreados {
  static const _clave = 'niveles_creados';
  static final List<NivelCreado> lista = [];

  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      lista
        ..clear()
        ..addAll([
          for (final t in prefs.getStringList(_clave) ?? const <String>[])
            NivelCreado.fromJson(jsonDecode(t) as Map<String, dynamic>)
        ]);
    } catch (_) {}
  }

  static Future<void> guardar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _clave, [for (final n in lista) jsonEncode(n.toJson())]);
    } catch (_) {}
  }

  static NivelCreado nuevo() {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final n = NivelCreado.nuevo(id, 'Mi nivel ${lista.length + 1}');
    lista.add(n);
    return n;
  }

  static Future<void> borrar(NivelCreado n) async {
    lista.remove(n);
    await guardar();
  }
}
