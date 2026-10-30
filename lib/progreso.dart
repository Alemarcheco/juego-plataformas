import 'package:shared_preferences/shared_preferences.dart';

import 'datos/logros.dart';
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

  /// Enemigos derrotados por tipo (para los logros).
  static final Map<String, int> derrotados = {};
  static final Set<String> logrados = {};

  /// Índice del último nivel principal (10-8) y del último secreto.
  static const ultimoPrincipal = 79;
  static const ultimoSecreto = 83;

  static int avance(Logro l) => switch (l.id) {
        'fuego' => derrotados['llamas'] ?? 0,
        'acido' => derrotados['acido'] ?? 0,
        'campeon' => completado(ultimoPrincipal) ? 1 : 0,
        'hongo' => completado(ultimoSecreto) ? 1 : 0,
        _ => 0,
      };

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
      for (var i = 0; i <= ultimoSecreto; i++) {
        final p = _prefs!.getInt('pescados_$i');
        if (p != null) pescados[i] = p;
      }
      monedero = _prefs!.getInt('monedero') ??
          pescados.values.fold<int>(0, (a, b) => a + b);
      comprados.addAll(_prefs!.getStringList('comprados') ?? const []);
      skinActual = _prefs!.getString('skin') ?? 'naranja';
      secreto = _prefs!.getBool('secreto') ?? false;
      for (final k in ['llamas', 'acido']) {
        derrotados[k] = _prefs!.getInt('derrotados_$k') ?? 0;
      }
      logrados.addAll(_prefs!.getStringList('logros') ?? const []);
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

  /// Cuenta un enemigo derrotado. Devuelve los logros que se acaban de ganar.
  static Future<List<Logro>> contarDerrota(String tipo) async {
    if (tipo != 'llamas' && tipo != 'acido') return const [];
    derrotados[tipo] = (derrotados[tipo] ?? 0) + 1;
    try {
      await _prefs?.setInt('derrotados_$tipo', derrotados[tipo]!);
    } catch (_) {}
    return revisarLogros();
  }

  /// Da los trajes de los logros conseguidos. Devuelve los nuevos.
  static Future<List<Logro>> revisarLogros() async {
    final nuevos = [
      for (final l in logros)
        if (!logrados.contains(l.id) && avance(l) >= l.meta) l
    ];
    if (nuevos.isEmpty) return nuevos;
    for (final l in nuevos) {
      logrados.add(l.id);
      comprados.add(l.skin);
    }
    try {
      await _prefs?.setStringList('logros', logrados.toList());
    } catch (_) {}
    await _guardarTienda();
    return nuevos;
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
    if (s.logro != null) return false;
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
