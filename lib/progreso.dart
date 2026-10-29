import 'package:shared_preferences/shared_preferences.dart';

import 'datos/skins.dart';

/// Guarda hasta qué nivel ha llegado Paco, los pescados y los trajes.
class Progreso {
  static const _claveDesbloqueado = 'desbloqueado';
  static SharedPreferences? _prefs;

  static int desbloqueado = 0; // índice del último nivel que se puede jugar
  static final Map<int, int> pescados = {}; // récord de cada nivel

  /// Pescados para gastar en la tienda (se suman al terminar cada nivel).
  static int monedero = 0;
  static final Set<String> comprados = {'naranja'};
  static String skinActual = 'naranja';

  /// Se encontró el camino secreto del nivel 9-5.
  static bool secreto = false;

  /// ¿Se puede jugar este nivel?
  static bool abierto(int indice) {
    if (indice < 80) return indice <= desbloqueado;
    if (!secreto) return false;
    return indice == 80 || completado(indice - 1);
  }

  static Skin get skin =>
      skins.firstWhere((s) => s.id == skinActual, orElse: () => skins.first);

  static Future<void> cargar() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      desbloqueado = _prefs!.getInt(_claveDesbloqueado) ?? 0;
      for (var i = 0; i < 80; i++) {
        final p = _prefs!.getInt('pescados_$i');
        if (p != null) pescados[i] = p;
      }
      monedero = _prefs!.getInt('monedero') ??
          pescados.values.fold<int>(0, (a, b) => a + b);
      comprados.addAll(_prefs!.getStringList('comprados') ?? const []);
      skinActual = _prefs!.getString('skin') ?? 'naranja';
      secreto = _prefs!.getBool('secreto') ?? false;
    } catch (_) {
      // Sin almacenamiento se juega igual, solo que no se guarda.
    }
  }

  static bool completado(int indice) => pescados.containsKey(indice);

  static Future<void> completar(int indice, int conseguidos) async {
    final antes = pescados[indice];
    if (antes == null || conseguidos > antes) pescados[indice] = conseguidos;
    if (indice < 79 && indice + 1 > desbloqueado) desbloqueado = indice + 1;
    monedero += conseguidos;
    try {
      await _prefs?.setInt('pescados_$indice', pescados[indice]!);
      await _prefs?.setInt(_claveDesbloqueado, desbloqueado);
      await _prefs?.setInt('monedero', monedero);
    } catch (_) {}
  }

  static Future<void> abrirSecreto() async {
    secreto = true;
    try {
      await _prefs?.setBool('secreto', true);
    } catch (_) {}
  }

  /// Compra un traje si hay pescados suficientes. Devuelve si se compró.
  static Future<bool> comprar(Skin s) async {
    if (comprados.contains(s.id)) return true;
    if (monedero < s.precio) return false;
    monedero -= s.precio;
    comprados.add(s.id);
    skinActual = s.id;
    await _guardarTienda();
    return true;
  }

  static Future<void> ponerse(Skin s) async {
    if (!comprados.contains(s.id)) return;
    skinActual = s.id;
    await _guardarTienda();
  }

  static Future<void> _guardarTienda() async {
    try {
      await _prefs?.setInt('monedero', monedero);
      await _prefs?.setStringList('comprados', comprados.toList());
      await _prefs?.setString('skin', skinActual);
    } catch (_) {}
  }
}
