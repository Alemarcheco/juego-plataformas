import 'package:shared_preferences/shared_preferences.dart';

/// Guarda hasta qué nivel ha llegado Paco y los pescados de cada nivel.
class Progreso {
  static const _claveDesbloqueado = 'desbloqueado';
  static SharedPreferences? _prefs;

  static int desbloqueado = 0; // índice del último nivel que se puede jugar
  static final Map<int, int> pescados = {};

  static Future<void> cargar() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      desbloqueado = _prefs!.getInt(_claveDesbloqueado) ?? 0;
      for (var i = 0; i < 80; i++) {
        final p = _prefs!.getInt('pescados_$i');
        if (p != null) pescados[i] = p;
      }
    } catch (_) {
      // Sin almacenamiento se juega igual, solo que no se guarda.
    }
  }

  static bool completado(int indice) => pescados.containsKey(indice);

  static Future<void> completar(int indice, int conseguidos) async {
    final antes = pescados[indice];
    if (antes == null || conseguidos > antes) pescados[indice] = conseguidos;
    if (indice + 1 > desbloqueado) desbloqueado = (indice + 1).clamp(0, 79);
    try {
      await _prefs?.setInt('pescados_$indice', pescados[indice]!);
      await _prefs?.setInt(_claveDesbloqueado, desbloqueado);
    } catch (_) {}
  }
}
