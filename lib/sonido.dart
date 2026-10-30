import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'datos/mundos.dart';

/// Canciones del juego: id -> nombre que se ve en el creador de niveles.
const Map<String, String> musicas = {
  'planicie': 'Aventura',
  'desierto': 'Desierto',
  'mar': 'Bajo el mar',
  'cielo': 'Entre nubes',
  'nieve': 'Nieve',
  'ciudad': 'Ciudad del futuro',
  'lava': 'Lava',
  'veneno': 'Veneno',
  'caja': 'Caja de pruebas',
  'bosque': 'Bosque abandonado',
  'castillo': 'Castillo',
  'jefe': 'Jefe',
  'secreto': 'Mundo gigante',
};

/// Canción de cada nivel del juego, según su fondo.
String musicaDe(Nivel n) {
  if (n.tipo == TipoNivel.agua || n.tema == Temas.marino) return 'mar';
  if (n.mundo == 11) return 'secreto';
  if (n.tipo == TipoNivel.fortaleza) return 'castillo';
  return switch (n.mundo) {
    1 => n.tipo == TipoNivel.cielo ? 'cielo' : 'planicie',
    2 => 'desierto',
    3 => 'mar',
    4 => 'cielo',
    5 => 'nieve',
    6 => 'ciudad',
    7 => 'lava',
    8 => 'veneno',
    9 => 'caja',
    _ => 'bosque',
  };
}

/// Música y efectos de sonido (archivos hechos con tools/sonidos.py).
class Sonido {
  static bool musicaActiva = true;
  static bool efectosActivos = true;

  static AudioPlayer? _musica;
  static final List<AudioPlayer> _efectos = [];
  static int _turno = 0;
  static String? _cancion;
  static bool _listo = false;
  static final Map<String, DateTime> _ultimo = {};

  static Future<void> iniciar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      musicaActiva = prefs.getBool('musica') ?? true;
      efectosActivos = prefs.getBool('efectos') ?? true;
      // Los efectos no deben cortar la música (ni la de otras apps)
      await AudioPlayer.global.setAudioContext(
          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
      _musica = AudioPlayer();
      await _musica!.setReleaseMode(ReleaseMode.loop);
      for (var i = 0; i < 6; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        _efectos.add(p);
      }
      _listo = true;
    } catch (_) {
      // Sin sonido se juega igual
    }
  }

  static Future<void> musica(String? id) async {
    if (id == _cancion) return;
    _cancion = id;
    await _tocarMusica();
  }

  static Future<void> _tocarMusica() async {
    final m = _musica;
    if (!_listo || m == null) return;
    try {
      await m.stop();
      final id = _cancion;
      if (id == null || !musicaActiva) return;
      await m.play(AssetSource('audio/musica_$id.ogg'), volume: 0.45);
    } catch (_) {}
  }

  /// Al salir de la app la música se para y al volver sigue.
  static Future<void> pausar() async {
    try {
      await _musica?.pause();
    } catch (_) {}
  }

  static Future<void> seguir() async {
    if (!musicaActiva || _cancion == null) return;
    try {
      await _musica?.resume();
    } catch (_) {}
  }

  static void efecto(String id) {
    if (!_listo || !efectosActivos || _efectos.isEmpty) return;
    // El mismo sonido muchas veces seguidas suena mal
    final ahora = DateTime.now();
    final antes = _ultimo[id];
    if (antes != null && ahora.difference(antes).inMilliseconds < 60) return;
    _ultimo[id] = ahora;
    final p = _efectos[_turno++ % _efectos.length];
    p.stop().then((_) => p.play(AssetSource('audio/efecto_$id.ogg'), volume: 0.7)).catchError((_) {});
  }

  static Future<void> cambiarMusica(bool activa) async {
    musicaActiva = activa;
    await _guardar();
    await _tocarMusica();
  }

  static Future<void> cambiarEfectos(bool activos) async {
    efectosActivos = activos;
    await _guardar();
  }

  static Future<void> _guardar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('musica', musicaActiva);
      await prefs.setBool('efectos', efectosActivos);
    } catch (_) {}
  }
}
