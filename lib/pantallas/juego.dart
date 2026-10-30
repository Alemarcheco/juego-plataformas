import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../datos/logros.dart';
import '../datos/mundos.dart';
import '../datos/skins.dart';
import '../juego/motor.dart';
import '../juego/pintor.dart';
import '../progreso.dart';
import 'comunes.dart';

class PantallaJuego extends StatefulWidget {
  final Nivel nivel;
  const PantallaJuego({super.key, required this.nivel});

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego>
    with SingleTickerProviderStateMixin {
  late Nivel nivel = widget.nivel;
  late Motor motor = Motor(nivel);
  late final Ticker _ticker;
  final _cuadro = ValueNotifier<int>(0);
  final _foco = FocusNode();
  Duration _anterior = Duration.zero;
  bool pausa = false;
  bool fin = false;

  /// Logro recién ganado que se enseña arriba un momento.
  Logro? _logro;
  int _logroCuadros = 0;

  // Teclado y botones táctiles se suman
  final Set<LogicalKeyboardKey> _teclas = {};
  bool _tIzq = false, _tDer = false, _tSalto = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration ahora) {
    final dt = (ahora - _anterior).inMicroseconds / 1e6;
    _anterior = ahora;
    if (pausa || fin || dt <= 0) return;
    _aplicarMandos();
    final vidasAntes = motor.vidas;
    final pescadosAntes = motor.pescados;
    final estadoAntes = motor.estado;
    final jefeAntes = motor.jefe?.vidas;
    motor.actualizar(dt);
    _cuadro.value++;
    if (motor.derrotados.isNotEmpty) {
      for (final t in motor.derrotados) {
        Progreso.contarDerrota(t.name).then(_avisarLogros);
      }
      motor.derrotados.clear();
    }
    if (_logro != null && --_logroCuadros <= 0) setState(() => _logro = null);
    if (motor.vidas != vidasAntes ||
        motor.pescados != pescadosAntes ||
        motor.estado != estadoAntes ||
        motor.jefe?.vidas != jefeAntes ||
        motor.jefe?.activo == true && jefeAntes == null) {
      setState(() {});
    }
    if (motor.terminado && !fin) {
      fin = true;
      Progreso.completar(nivel.indice, motor.pescados)
          .then((_) => Progreso.revisarLogros())
          .then(_avisarLogros);
      if (motor.secretoEncontrado) Progreso.abrirSecreto();
      setState(() {});
    }
  }

  void _avisarLogros(List<Logro> nuevos) {
    if (nuevos.isEmpty || !mounted) return;
    setState(() {
      _logro = nuevos.last;
      _logroCuadros = 60 * 4;
    });
  }

  void _aplicarMandos() {
    final m = motor.mandos;
    m.izquierda = _tIzq ||
        _teclas.contains(LogicalKeyboardKey.arrowLeft) ||
        _teclas.contains(LogicalKeyboardKey.keyA);
    m.derecha = _tDer ||
        _teclas.contains(LogicalKeyboardKey.arrowRight) ||
        _teclas.contains(LogicalKeyboardKey.keyD);
    m.salto = _tSalto ||
        _teclas.contains(LogicalKeyboardKey.space) ||
        _teclas.contains(LogicalKeyboardKey.arrowUp) ||
        _teclas.contains(LogicalKeyboardKey.keyW);
  }

  KeyEventResult _tecla(FocusNode _, KeyEvent e) {
    if (e is KeyDownEvent) {
      if (e.logicalKey == LogicalKeyboardKey.escape ||
          e.logicalKey == LogicalKeyboardKey.keyP) {
        setState(() => pausa = !pausa);
      }
      _teclas.add(e.logicalKey);
    } else if (e is KeyUpEvent) {
      _teclas.remove(e.logicalKey);
    }
    return KeyEventResult.handled;
  }

  void _cambiarNivel(Nivel n) {
    setState(() {
      nivel = n;
      motor = Motor(n);
      fin = false;
      pausa = false;
    });
  }

  void _reiniciar() {
    setState(() {
      motor.reiniciar();
      fin = false;
      pausa = false;
    });
  }

  Nivel? get _siguiente {
    if (motor.secretoEncontrado) return mundoSecreto.niveles.first;
    final i = nivel.indice + 1;
    if (nivel.indice == 79 || i >= todosLosNiveles.length) return null;
    return todosLosNiveles[i];
  }

  @override
  void dispose() {
    _ticker.dispose();
    _foco.dispose();
    _cuadro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _foco,
        autofocus: true,
        onKeyEvent: _tecla,
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: PintorJuego(motor, _cuadro)),
              ),
            ),
            SafeArea(child: _hud()),
            if (!fin) SafeArea(child: _controles()),
            if (_logro != null) _avisoLogro(_logro!),
            if (pausa) _ventanaPausa(),
            if (fin) _ventanaFin(),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    final jefe = motor.jefe;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < motor.vidas; i++)
                const Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: Icon(Icons.favorite_rounded,
                      color: Color(0xFFFF4D6D), size: 26),
                ),
              const SizedBox(width: 12),
              const Icon(Icons.set_meal_rounded,
                  color: Color(0xFFFFC93C), size: 24),
              const SizedBox(width: 4),
              _texto('${motor.pescados}'),
              const Spacer(),
              _texto('Mundo ${nivel.mundo}-${nivel.numero} · ${nivel.tema.nombre}'),
              const SizedBox(width: 8),
              _botonRedondo(Icons.pause_rounded, () {
                setState(() => pausa = true);
              }),
            ],
          ),
          if (jefe != null && jefe.activo && jefe.derrotado == 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                children: [
                  _texto(jefe.datos.nombre),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: jefe.vidas / jefe.datos.vidas,
                        minHeight: 10,
                        color: const Color(0xFFFF4D6D),
                        backgroundColor: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _avisoLogro(Logro l) {
    final skin = skins.firstWhere((s) => s.id == l.skin);
    return Positioned(
      top: 56,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
          decoration: BoxDecoration(
            color: const Color(0xEE1F2D40),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFC93C), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RetratoPaco(tamano: 46, skin: skin),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('¡Logro: ${l.nombre}!',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFFFC93C))),
                  Text('Ganaste el traje ${skin.nombre}',
                      style: const TextStyle(fontSize: 14, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _texto(String t) => Text(
        t,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [
            Shadow(
                color: Colors.black.withValues(alpha: 0.7),
                offset: const Offset(1.5, 1.5)),
          ],
        ),
      );

  Widget _botonRedondo(IconData icono, VoidCallback onTap) => Material(
        color: Colors.black38,
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icono, color: Colors.white),
          onPressed: onTap,
        ),
      );

  Widget _controles() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            BotonTactil(
              icono: Icons.arrow_back_rounded,
              alCambiar: (v) => _tIzq = v,
            ),
            const SizedBox(width: 14),
            BotonTactil(
              icono: Icons.arrow_forward_rounded,
              alCambiar: (v) => _tDer = v,
            ),
            const Spacer(),
            BotonTactil(
              icono: motor.enAgua ? Icons.waves_rounded : Icons.arrow_upward_rounded,
              tamano: 92,
              color: const Color(0xFFF59A33),
              alCambiar: (v) => _tSalto = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _velo(Widget hijo) => Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          alignment: Alignment.center,
          child: SingleChildScrollView(child: hijo),
        ),
      );

  Widget _ventanaPausa() {
    return _velo(Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Pausa',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            BotonJuego(
                texto: 'Seguir',
                icono: Icons.play_arrow_rounded,
                onPressed: () => setState(() => pausa = false)),
            BotonJuego(
                texto: 'Reiniciar',
                icono: Icons.refresh_rounded,
                color: const Color(0xFF4A90D9),
                onPressed: _reiniciar),
            BotonJuego(
                texto: 'Mapa',
                icono: Icons.map_rounded,
                color: const Color(0xFF5A6578),
                onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ],
    ));
  }

  Widget _ventanaFin() {
    final siguiente = _siguiente;
    final ultimo = nivel.indice == 79;
    final jefe = motor.jefe;
    final titulo = motor.secretoEncontrado
        ? '¡Encontraste el mundo secreto!'
        : ultimo
            ? '¡Paco venció al Perro Supremo!'
            : jefe != null
                ? '¡Venciste a ${jefe.datos.nombre}!'
                : '¡Nivel completado!';
    return _velo(Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const RetratoPaco(tamano: 90),
        const SizedBox(height: 8),
        Text(titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.set_meal_rounded, color: Color(0xFFFFC93C)),
            const SizedBox(width: 6),
            Text('${motor.pescados} de ${motor.totalPescados} pescados',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        if (ultimo)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('¡Terminaste los 10 mundos! Eres un campeón.',
                style: TextStyle(fontSize: 16)),
          ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            if (siguiente != null)
              BotonJuego(
                  texto: motor.secretoEncontrado ? 'Entrar' : 'Siguiente',
                  icono: Icons.arrow_forward_rounded,
                  onPressed: () => _cambiarNivel(siguiente)),
            BotonJuego(
                texto: 'Otra vez',
                icono: Icons.refresh_rounded,
                color: const Color(0xFF4A90D9),
                onPressed: _reiniciar),
            BotonJuego(
                texto: 'Mapa',
                icono: Icons.map_rounded,
                color: const Color(0xFF5A6578),
                onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ],
    ));
  }
}

/// Botón que avisa cuando se aprieta y cuando se suelta (para varios dedos).
class BotonTactil extends StatefulWidget {
  final IconData icono;
  final double tamano;
  final Color color;
  final ValueChanged<bool> alCambiar;
  const BotonTactil({
    super.key,
    required this.icono,
    required this.alCambiar,
    this.tamano = 78,
    this.color = const Color(0xFF2A3546),
  });

  @override
  State<BotonTactil> createState() => _BotonTactilState();
}

class _BotonTactilState extends State<BotonTactil> {
  final Set<int> _dedos = {};

  void _actualizar() {
    widget.alCambiar(_dedos.isNotEmpty);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final apretado = _dedos.isNotEmpty;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        _dedos.add(e.pointer);
        _actualizar();
      },
      onPointerUp: (e) {
        _dedos.remove(e.pointer);
        _actualizar();
      },
      onPointerCancel: (e) {
        _dedos.remove(e.pointer);
        _actualizar();
      },
      child: Container(
        width: widget.tamano,
        height: widget.tamano,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: apretado ? 0.85 : 0.5),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
        ),
        child: Icon(widget.icono, color: Colors.white, size: widget.tamano * 0.5),
      ),
    );
  }
}
