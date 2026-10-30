import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../datos/creados.dart';
import '../datos/mundos.dart';
import '../juego/generador.dart';
import '../juego/motor.dart';
import '../juego/pintor.dart';
import '../progreso.dart';
import '../sonido.dart';
import 'comunes.dart';
import 'juego.dart';

/// Ofrece comprar el creador de niveles. Devuelve si ya se tiene.
Future<bool> pedirCreador(BuildContext context) async {
  if (Progreso.creador) return true;
  final alcanza = Progreso.monedero >= Progreso.precioCreador;
  final si = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Creador de niveles'),
      content: Text(alcanza
          ? 'Haz tus propios niveles con todo lo del juego. '
              'Cuesta ${Progreso.precioCreador} pescados y tienes ${Progreso.monedero}.'
          : 'Cuesta ${Progreso.precioCreador} pescados y tienes ${Progreso.monedero}. '
              '¡Recoge más pescados en los niveles!'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Ahora no')),
        if (alcanza)
          FilledButton.icon(
              onPressed: () => Navigator.pop(c, true),
              icon: const Icon(Icons.set_meal_rounded),
              label: Text('Comprar por ${Progreso.precioCreador}')),
      ],
    ),
  );
  if (si != true) return false;
  return Progreso.comprarCreador();
}

/// Lista de los niveles hechos por el jugador.
class PantallaCreador extends StatefulWidget {
  const PantallaCreador({super.key});

  @override
  State<PantallaCreador> createState() => _PantallaCreadorState();
}

class _PantallaCreadorState extends State<PantallaCreador> {
  bool _cargado = false;

  @override
  void initState() {
    super.initState();
    NivelesCreados.cargar().then((_) {
      if (mounted) setState(() => _cargado = true);
    });
  }

  Future<void> _editar(NivelCreado n) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PantallaEditor(nivel: n)));
    await NivelesCreados.guardar();
    if (mounted) setState(() {});
  }

  Future<void> _jugar(NivelCreado n) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PantallaJuego(nivel: n.nivel, creado: n)));
  }

  Future<void> _borrar(NivelCreado n) async {
    final si = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('¿Borrar "${n.nombre}"?'),
        content: const Text('No se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Borrar')),
        ],
      ),
    );
    if (si == true) {
      await NivelesCreados.borrar(n);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = NivelesCreados.lista;
    return Scaffold(
      backgroundColor: const Color(0xFF14202E),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text('Creador de niveles',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  BotonJuego(
                    texto: 'NUEVO NIVEL',
                    icono: Icons.add_rounded,
                    onPressed: () => _editar(NivelesCreados.nuevo()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !_cargado
                  ? const Center(child: CircularProgressIndicator())
                  : lista.isEmpty
                      ? const Center(
                          child: Text(
                              'Todavía no tienes niveles.\nToca NUEVO NIVEL para hacer el primero.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white70)),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(16),
                          children: [for (final n in lista) _tarjeta(n)],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta(NivelCreado n) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2D40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: n.temaElegido.cieloArriba, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VistaPrevia(nivel: n),
            ),
          ),
          const SizedBox(height: 8),
          Text(n.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(
              '${n.temaElegido.nombre} · ${musicas[n.musica] ?? ''}'
              '${n.agua ? ' · bajo el agua' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _jugar(n),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Jugar'),
                ),
              ),
              IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _editar(n),
                  icon: const Icon(Icons.edit_rounded)),
              IconButton(
                  tooltip: 'Borrar',
                  onPressed: () => _borrar(n),
                  icon: const Icon(Icons.delete_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dibujo pequeño del principio de un nivel creado.
class VistaPrevia extends StatelessWidget {
  final NivelCreado nivel;
  const VistaPrevia({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final m = Motor(nivel.nivel, crearMapa: nivel.mapa);
    m.camX = 0;
    return CustomPaint(
        painter: PintorJuego(m, ValueNotifier(0)), size: Size.infinite);
  }
}

// ---------------------------------------------------------------- editor

/// Lo que se pone al tocar el mapa.
sealed class Herramienta {
  const Herramienta();
}

class PonerCasilla extends Herramienta {
  final Casilla casilla;
  const PonerCasilla(this.casilla);
}

class PonerEnemigo extends Herramienta {
  final TipoEnemigo tipo;
  const PonerEnemigo(this.tipo);
}

enum Marca { inicio, control, meta }

class PonerMarca extends Herramienta {
  final Marca marca;
  const PonerMarca(this.marca);
}

class Borrar extends Herramienta {
  const Borrar();
}

class PantallaEditor extends StatefulWidget {
  final NivelCreado nivel;
  const PantallaEditor({super.key, required this.nivel});

  @override
  State<PantallaEditor> createState() => _PantallaEditorState();
}

class _PantallaEditorState extends State<PantallaEditor> {
  late final NivelCreado n = widget.nivel;
  late Motor motor;
  final _repintar = ValueNotifier(0);
  double camX = 0;

  /// El editor enseña las casillas más grandes que el juego, así que
  /// también se mueve de arriba abajo (en casillas).
  double camY = 0;
  Size _vista = Size.zero;
  int pestana = 0;
  Herramienta herramienta = const PonerCasilla(Casilla.tierra);
  Timer? _guardado;
  (int, int)? _ultima;

  static const pestanas = ['Bloques', 'Objetos', 'Enemigos', 'Paco y banderas'];

  static const bloques = [
    Casilla.tierra,
    Casilla.ladrillo,
    Casilla.pinchos,
    Casilla.liquido,
  ];
  static const objetos = [Casilla.moneda, Casilla.corazon];

  @override
  void initState() {
    super.initState();
    _rehacer();
  }

  @override
  void dispose() {
    _guardado?.cancel();
    NivelesCreados.guardar();
    _repintar.dispose();
    super.dispose();
  }

  void _rehacer() {
    motor = Motor(n.nivel, crearMapa: n.mapa);
    for (final e in motor.enemigos) {
      e.activo = true;
    }
    motor.camX = camX;
    _repintar.value++;
  }

  void _cambio() {
    _rehacer();
    setState(() {});
    // Se guarda solo, un momento después del último cambio
    _guardado?.cancel();
    _guardado = Timer(const Duration(seconds: 1), NivelesCreados.guardar);
  }

  /// Tamaño de una casilla en pantalla: al menos 30 para poder tocarla.
  static double _escala(Size s) => max(s.height / Mapa.alto, 30);

  void _mover(double dx, [double dy = 0]) {
    final s = _escala(_vista);
    final ancho = _vista.width / s;
    final alto = _vista.height / s;
    camX = (camX + dx).clamp(0.0, max(0.0, n.ancho - ancho));
    camY = (camY + dy).clamp(0.0, max(0.0, Mapa.alto - alto));
    motor.camX = camX;
    _repintar.value++;
  }

  void _tocar(Offset p, Size size) {
    final s = _escala(size);
    final x = (p.dx / s + camX).floor();
    var y = (p.dy / s + camY).floor();
    if (x < 0 || x >= n.ancho || y < 0 || y >= Mapa.alto) return;
    // Enemigos, Paco y banderas se ponen encima del suelo, sin romperlo
    if (herramienta is PonerEnemigo || herramienta is PonerMarca) {
      while (y > 0 && esSolida(n.casillas[x][y])) {
        y--;
      }
    }
    if (_ultima == (x, y)) return;
    _ultima = (x, y);
    switch (herramienta) {
      case PonerCasilla(:final casilla):
        n.casillas[x][y] = casilla;
        _quitarEnemigo(x, y);
      case PonerEnemigo(:final tipo):
        _quitarEnemigo(x, y);
        if (n.casillas[x][y] != Casilla.liquido) n.casillas[x][y] = Casilla.vacio;
        // Los de suelo se apoyan en el fondo de la casilla
        n.enemigos.add(
            Aparicion(tipo, x + 0.03, _flota(tipo) ? y + 0.15 : y + 1.0));
      case PonerMarca(:final marca):
        if (esSolida(n.casillas[x][y])) n.casillas[x][y] = Casilla.vacio;
        switch (marca) {
          case Marca.inicio:
            n.inicioX = x;
            n.inicioY = y;
          case Marca.control:
            n.controlX = x;
            n.controlY = y;
          case Marca.meta:
            n.metaX = x;
            n.metaY = y;
        }
      case Borrar():
        n.casillas[x][y] = Casilla.vacio;
        _quitarEnemigo(x, y);
        if (n.controlX == x && n.controlY == y) n.controlX = n.controlY = null;
    }
    _cambio();
  }

  static bool _flota(TipoEnemigo t) =>
      t == TipoEnemigo.volador || t == TipoEnemigo.fuego || t.name.startsWith('pez');

  void _quitarEnemigo(int x, int y) {
    n.enemigos.removeWhere((e) =>
        e.x.floor() == x && (_flota(e.tipo) ? e.y : e.y - 1).floor() == y);
  }

  Future<void> _cambiarNombre() async {
    final control = TextEditingController(text: n.nombre);
    final nombre = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Nombre del nivel'),
        content: TextField(
          controller: control,
          autofocus: true,
          maxLength: 30,
          onSubmitted: (t) => Navigator.pop(c, t),
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(c, control.text),
              child: const Text('Listo')),
        ],
      ),
    );
    if (nombre != null && nombre.trim().isNotEmpty) {
      n.nombre = nombre.trim();
      _cambio();
    }
  }

  Future<void> _elegirFondo() async {
    final tema = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Fondo'),
        children: [
          SizedBox(
            width: 520,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final MapEntry(:key, :value) in Temas.todos.entries)
                  InkWell(
                    onTap: () => Navigator.pop(c, key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 118,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: key == n.tema
                                ? const Color(0xFFF59A33)
                                : Colors.white24,
                            width: 2),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  value.cieloArriba,
                                  value.cieloAbajo,
                                  value.cesped,
                                  value.tierra
                                ],
                                stops: const [0, 0.65, 0.65, 0.8],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(value.nombre,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (tema != null) {
      n.tema = tema;
      _cambio();
    }
  }

  Future<void> _elegirMusica() async {
    final musica = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Música'),
        children: [
          for (final MapEntry(:key, :value) in musicas.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, key),
              child: Row(
                children: [
                  Icon(
                      key == n.musica
                          ? Icons.music_note_rounded
                          : Icons.music_note_outlined,
                      color: key == n.musica ? const Color(0xFFF59A33) : null),
                  const SizedBox(width: 10),
                  Text(value, style: const TextStyle(fontSize: 17)),
                ],
              ),
            ),
        ],
      ),
    );
    if (musica != null) {
      n.musica = musica;
      _cambio();
    }
  }

  Future<void> _elegirLargo() async {
    var largo = n.ancho.toDouble();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text('Largo del nivel: ${largo.round()} casillas'),
          content: Slider(
            value: largo,
            min: 30,
            max: 300,
            divisions: 27,
            onChanged: (v) => set(() => largo = v),
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Listo')),
          ],
        ),
      ),
    );
    if (ok == true) {
      n.cambiarAncho(largo.round());
      _mover(0);
      _cambio();
    }
  }

  Future<void> _probar() async {
    await NivelesCreados.guardar();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PantallaJuego(nivel: n.nivel, creado: n)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14202E),
      body: SafeArea(
        child: Column(
          children: [
            _barra(),
            Expanded(child: _zona()),
            _paleta(),
          ],
        ),
      ),
    );
  }

  Widget _boton(IconData icono, String texto, VoidCallback onTap,
          {Color color = const Color(0xFF2C3E57)}) =>
      Padding(
        padding: const EdgeInsets.only(left: 6),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: onTap,
          icon: Icon(icono, size: 20),
          label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );

  Widget _barra() {
    return Container(
      color: const Color(0xFF1F2D40),
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Flexible(
            child: InkWell(
              onTap: _cambiarNombre,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(n.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          _boton(Icons.landscape_rounded, n.temaElegido.nombre, _elegirFondo),
          _boton(Icons.music_note_rounded, musicas[n.musica] ?? '', _elegirMusica),
          _boton(Icons.straighten_rounded, '${n.ancho}', _elegirLargo),
          _boton(Icons.waves_rounded, n.agua ? 'Agua: sí' : 'Agua: no', () {
            n.agua = !n.agua;
            _cambio();
          }, color: n.agua ? const Color(0xFF2A7FC0) : const Color(0xFF2C3E57)),
          _boton(Icons.play_arrow_rounded, 'Probar', _probar,
              color: const Color(0xFF3FAE5A)),
        ],
      ),
    );
  }

  Widget _zona() {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      if (_vista != size) {
        final primera = _vista == Size.zero;
        _vista = size;
        // Al abrir, se ve el suelo
        if (primera) camY = 99;
        WidgetsBinding.instance.addPostFrameCallback((_) => _mover(0));
      }
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (d) {
                _ultima = null;
                _tocar(d.localPosition, size);
              },
              onScaleStart: (_) => _ultima = null,
              onScaleUpdate: (d) {
                if (d.pointerCount >= 2) {
                  final s = _escala(size);
                  _mover(-d.focalPointDelta.dx / s, -d.focalPointDelta.dy / s);
                } else {
                  _tocar(d.localFocalPoint, size);
                }
              },
              child: CustomPaint(
                painter: _VistaEditor(this),
                size: size,
              ),
            ),
          ),
          // Flechas para moverse por el nivel
          Positioned(
            left: 6,
            top: 6,
            child: _flecha(Icons.chevron_left_rounded, () => _mover(-6)),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Column(
              children: [
                _flecha(Icons.chevron_right_rounded, () => _mover(6)),
                const SizedBox(height: 6),
                _flecha(Icons.keyboard_arrow_up_rounded, () => _mover(0, -3)),
                const SizedBox(height: 6),
                _flecha(Icons.keyboard_arrow_down_rounded, () => _mover(0, 3)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _flecha(IconData icono, VoidCallback alTocar) => Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        child: IconButton(
          iconSize: 30,
          visualDensity: VisualDensity.compact,
          icon: Icon(icono, color: Colors.white),
          onPressed: alTocar,
        ),
      );

  Widget _paleta() {
    final items = <(Herramienta, Widget)>[
      if (pestana == 0)
        for (final c in bloques) (PonerCasilla(c), _IconoCasilla(c, n)),
      if (pestana == 1)
        for (final c in objetos) (PonerCasilla(c), _IconoCasilla(c, n)),
      if (pestana == 2)
        for (final t in TipoEnemigo.values) (PonerEnemigo(t), _IconoEnemigo(t)),
      if (pestana == 3) ...[
        (const PonerMarca(Marca.inicio), const _IconoMarca(Marca.inicio)),
        (const PonerMarca(Marca.control), const _IconoMarca(Marca.control)),
        (const PonerMarca(Marca.meta), const _IconoMarca(Marca.meta)),
      ],
    ];
    return Container(
      color: const Color(0xFF1F2D40),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < pestanas.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(pestanas[i]),
                    selected: pestana == i,
                    onSelected: (_) => setState(() => pestana = i),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 58,
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final (h, icono) in items)
                        _casillaPaleta(h, icono),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _casillaPaleta(
                    const Borrar(),
                    const Center(
                        child: Text('Borrar',
                            style: TextStyle(fontWeight: FontWeight.w900))),
                    color: const Color(0xFF7A2B33),
                    ancho: 86),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _elegida(Herramienta h) => switch ((h, herramienta)) {
        (PonerCasilla(casilla: final a), PonerCasilla(casilla: final b)) => a == b,
        (PonerEnemigo(tipo: final a), PonerEnemigo(tipo: final b)) => a == b,
        (PonerMarca(marca: final a), PonerMarca(marca: final b)) => a == b,
        (Borrar(), Borrar()) => true,
        _ => false,
      };

  Widget _casillaPaleta(Herramienta h, Widget icono,
      {Color color = const Color(0xFF2C3E57), double ancho = 70}) {
    return GestureDetector(
      onTap: () => setState(() => herramienta = h),
      child: Container(
        width: ancho,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _elegida(h) ? const Color(0xFFFFE14A) : Colors.transparent,
              width: 3),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(9), child: icono),
      ),
    );
  }
}

/// El nivel como en el juego pero con casillas grandes y una cuadrícula.
class _VistaEditor extends CustomPainter {
  final _PantallaEditorState e;
  _VistaEditor(this.e) : super(repaint: e._repintar);

  @override
  void paint(Canvas c, Size size) {
    final s = _PantallaEditorState._escala(size);
    final motor = e.motor;
    c.save();
    c.clipRect(Offset.zero & size);
    c.translate(0, -e.camY * s);
    PintorJuego(motor, e._repintar).paint(c, Size(size.width, s * Mapa.alto));
    final linea = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    final alto = s * Mapa.alto;
    final desfase = (motor.camX % 1) * s;
    for (var x = -desfase; x < size.width; x += s) {
      c.drawLine(Offset(x, 0), Offset(x, alto), linea);
    }
    for (var y = 0.0; y <= alto + 0.5; y += s) {
      c.drawLine(Offset(0, y), Offset(size.width, y), linea);
    }
    // Más allá del final del nivel
    final fin = (motor.mapa.ancho - motor.camX) * s;
    if (fin < size.width) {
      c.drawRect(Rect.fromLTRB(fin, 0, size.width, alto),
          Paint()..color = Colors.black54);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _VistaEditor old) => true;
}

/// Pinta una casilla o un enemigo como en el juego, para la paleta.
class _Muestra extends CustomPainter {
  final Motor motor;
  _Muestra(this.motor);

  @override
  void paint(Canvas c, Size size) {
    // La muestra está en la casilla (1, 1); se dibuja el nivel entero a una
    // escala en la que esa casilla llena el cuadro.
    final s = size.height / 1.5;
    c.save();
    c.translate(-s * 0.75 + (size.width - s * 1.5) / 2, -s * 0.6);
    PintorJuego(motor, ValueNotifier(0))
        .paint(c, Size(s * Mapa.alto * 2, s * Mapa.alto));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _Muestra old) => old.motor != motor;
}

Motor _motorMuestra(Tema tema, {Casilla? casilla, TipoEnemigo? enemigo}) {
  final agua = enemigo != null && enemigo.name.startsWith('pez');
  final nivel = Nivel(1, 1, agua ? TipoNivel.agua : TipoNivel.suelo,
      agua ? Temas.marino : tema,
      creado: '');
  Mapa crear() {
    final m = Mapa(6);
    if (casilla != null) m.casillas[1][1] = casilla;
    if (enemigo != null) {
      m.enemigos.add(Aparicion(enemigo, 1.05,
          enemigo == TipoEnemigo.volador || enemigo == TipoEnemigo.fuego || agua ? 1.2 : 2.0));
    }
    m.inicioX = 50; // Paco fuera de la vista
    return m;
  }

  final m = Motor(nivel, crearMapa: crear);
  m.paco.x = 50;
  m.camX = 0;
  return m;
}

class _IconoCasilla extends StatelessWidget {
  final Casilla casilla;
  final NivelCreado nivel;
  const _IconoCasilla(this.casilla, this.nivel);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: _Muestra(_motorMuestra(nivel.temaElegido, casilla: casilla)),
        size: Size.infinite);
  }
}

class _IconoEnemigo extends StatelessWidget {
  final TipoEnemigo tipo;
  const _IconoEnemigo(this.tipo);

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _Muestra(_motorMuestra(Temas.planicie, enemigo: tipo)),
      size: Size.infinite);
}

class _IconoMarca extends StatelessWidget {
  final Marca marca;
  const _IconoMarca(this.marca);

  @override
  Widget build(BuildContext context) => switch (marca) {
        Marca.inicio => const Center(child: RetratoPaco(tamano: 44)),
        Marca.control =>
          const Icon(Icons.flag_rounded, color: Color(0xFF4CD964), size: 38),
        Marca.meta =>
          const Icon(Icons.sports_score_rounded, color: Color(0xFFFF8A1F), size: 38),
      };
}
