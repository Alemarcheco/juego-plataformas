import 'package:shared_preferences/shared_preferences.dart';

import 'datos/logros.dart';
import 'datos/mundos.dart';
import 'datos/skins.dart';
import 'juego/generador.dart';

/// Los dos perfiles del juego. Cada uno guarda su propio progreso.
class Perfil {
  final String id;
  final String nombre;
  const Perfil(this.id, this.nombre);
}

const perfiles = [Perfil('tiborio', 'Tiborio'), Perfil('buterio', 'Buterio')];

/// Guarda hasta qué nivel ha llegado Paco, los pescados y los trajes.
class Progreso {
  static const _claveDesbloqueado = 'desbloqueado';
  static SharedPreferences? _prefs;

  /// Perfil que está jugando. Tiborio usa las claves de antes, así que la
  /// partida que ya había pasa a ser la suya.
  static String perfil = 'tiborio';
  static String _k(String clave) =>
      perfil == 'tiborio' ? clave : '${perfil}_$clave';

  static int desbloqueado = 0; // índice del último nivel que se puede jugar
  static final Map<int, int> pescados = {}; // récord de cada nivel

  /// Pescados para gastar en la tienda (se suman al terminar cada nivel).
  static int monedero = 0;
  static final Set<String> comprados = {'naranja'};
  static String skinActual = 'naranja';

  /// Se encontró el camino secreto del nivel 9-5.
  static bool secreto = false;

  /// El creador de niveles se compra en la tienda.
  static const precioCreador = 100;
  static bool creador = false;

  /// Enemigos derrotados por tipo (para los logros).
  static final Map<String, int> derrotados = {};
  static final Set<String> logrados = {};

  /// Índice del último nivel principal (10-8), del último secreto y del
  /// nivel secreto del 3-3.
  static const ultimoPrincipal = 79;
  static const ultimoSecreto = 83;
  static const arcoiris = 84;

  static int avance(Logro l) => switch (l.id) {
        'fuego' => derrotados['llamas'] ?? 0,
        'acido' => derrotados['acido'] ?? 0,
        'hielo' => derrotados['hielo'] ?? 0,
        'angel' => derrotados['volador'] ?? 0,
        'resorte' => derrotados['saltarin'] ?? 0,
        'espinas' => derrotados['espinoso'] ?? 0,
        'campeon' => completado(ultimoPrincipal) ? 1 : 0,
        'hongo' => completado(ultimoSecreto) ? 1 : 0,
        'arcoiris' => completado(arcoiris) ? 1 : 0,
        _ => 0,
      };

  /// ¿Se puede jugar este nivel?
  static bool abierto(int indice) {
    if (indice < 80) return indice <= desbloqueado;
    if (indice == arcoiris) return completado(arcoiris);
    if (!secreto) return false;
    return indice == 80 || completado(indice - 1);
  }

  static Skin get skin =>
      skins.firstWhere((s) => s.id == skinActual, orElse: () => skins.first);

  /// Jefes que ya se vencieron (se pueden poner en el creador).
  static bool jefeVencido(Nivel n) =>
      completado(n.miniJefe != null ? arcoiris : n.indice);

  /// Perros gigantes en el creador: al superar el mundo gigante.
  static bool get gigantes => completado(ultimoSecreto);

  // ------------------------------------------------------------ 100 %
  static final Map<int, int> _totales = {};

  /// Pescados que hay en un nivel.
  static int totalPescados(int indice) => _totales.putIfAbsent(indice, () {
        final m = generarMapa(todosLosNiveles[indice]);
        var n = 0;
        for (final col in m.casillas) {
          for (final c in col) {
            if (c == Casilla.moneda) n++;
          }
        }
        return n;
      });

  /// De 0 a 100: la mitad por terminar cada nivel (los secretos también) y
  /// la otra mitad por sus pescados.
  static double porcentaje() {
    final n = todosLosNiveles.length;
    var puntos = 0.0;
    for (var i = 0; i < n; i++) {
      final r = pescados[i];
      if (r == null) continue;
      final total = totalPescados(i);
      puntos += 0.5 + 0.5 * (total == 0 ? 1 : (r / total).clamp(0.0, 1.0));
    }
    return puntos / n * 100;
  }

  static Future<void> elegirPerfil(String id) async {
    perfil = id;
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs!.setString('perfil', id);
    } catch (_) {}
    await cargar();
  }

  static Future<void> cargar() async {
    desbloqueado = 0;
    pescados.clear();
    monedero = 0;
    comprados
      ..clear()
      ..add('naranja');
    skinActual = 'naranja';
    secreto = false;
    creador = false;
    derrotados.clear();
    logrados.clear();
    try {
      _prefs = await SharedPreferences.getInstance();
      final p = _prefs!;
      desbloqueado = p.getInt(_k(_claveDesbloqueado)) ?? 0;
      for (var i = 0; i < todosLosNiveles.length; i++) {
        final r = p.getInt(_k('pescados_$i'));
        if (r != null) pescados[i] = r;
      }
      monedero = p.getInt(_k('monedero')) ??
          pescados.values.fold<int>(0, (a, b) => a + b);
      comprados.addAll(p.getStringList(_k('comprados')) ?? const []);
      skinActual = p.getString(_k('skin')) ?? 'naranja';
      secreto = p.getBool(_k('secreto')) ?? false;
      for (final k in enemigosDeLogros) {
        derrotados[k] = p.getInt(_k('derrotados_$k')) ?? 0;
      }
      logrados.addAll(p.getStringList(_k('logros')) ?? const []);
      creador = p.getBool(_k('creador')) ?? false;
    } catch (_) {
      // Sin almacenamiento se juega igual, solo que no se guarda.
    }
  }

  /// Perfil elegido la última vez (o null si nunca se eligió).
  static Future<String?> ultimoPerfil() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      return _prefs!.getString('perfil');
    } catch (_) {
      return null;
    }
  }

  static bool completado(int indice) => pescados.containsKey(indice);

  static Future<void> completar(int indice, int conseguidos) async {
    final antes = pescados[indice];
    if (antes == null || conseguidos > antes) pescados[indice] = conseguidos;
    if (indice < 79 && indice + 1 > desbloqueado) desbloqueado = indice + 1;
    monedero += conseguidos;
    try {
      await _prefs?.setInt(_k('pescados_$indice'), pescados[indice]!);
      await _prefs?.setInt(_k(_claveDesbloqueado), desbloqueado);
      await _prefs?.setInt(_k('monedero'), monedero);
    } catch (_) {}
  }

  /// Cuenta un enemigo derrotado. Devuelve los logros que se acaban de ganar.
  static Future<List<Logro>> contarDerrota(String tipo) async {
    if (!enemigosDeLogros.contains(tipo)) return const [];
    derrotados[tipo] = (derrotados[tipo] ?? 0) + 1;
    try {
      await _prefs?.setInt(_k('derrotados_$tipo'), derrotados[tipo]!);
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
      await _prefs?.setStringList(_k('logros'), logrados.toList());
    } catch (_) {}
    await _guardarTienda();
    return nuevos;
  }

  static Future<void> abrirSecreto() async {
    secreto = true;
    try {
      await _prefs?.setBool(_k('secreto'), true);
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

  static Future<bool> comprarCreador() async {
    if (creador) return true;
    if (monedero < precioCreador) return false;
    monedero -= precioCreador;
    creador = true;
    try {
      await _prefs?.setBool(_k('creador'), true);
      await _prefs?.setInt(_k('monedero'), monedero);
    } catch (_) {}
    return true;
  }

  static Future<void> ponerse(Skin s) async {
    if (!comprados.contains(s.id)) return;
    skinActual = s.id;
    await _guardarTienda();
  }

  static Future<void> _guardarTienda() async {
    try {
      await _prefs?.setInt(_k('monedero'), monedero);
      await _prefs?.setStringList(_k('comprados'), comprados.toList());
      await _prefs?.setString(_k('skin'), skinActual);
    } catch (_) {}
  }
}
