import 'package:flutter_test/flutter_test.dart';
import 'package:paco_aventuras/datos/logros.dart';
import 'package:paco_aventuras/datos/skins.dart';
import 'package:paco_aventuras/datos/mundos.dart';
import 'package:paco_aventuras/progreso.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Cada logro da un traje que existe', () {
    for (final l in logros) {
      expect(skins.where((s) => s.id == l.skin && s.logro == l.id), hasLength(1));
    }
  });

  test('10 perros de fuego dan el gato de fuego', () async {
    for (var i = 0; i < 9; i++) {
      expect(await Progreso.contarDerrota('llamas'), isEmpty);
    }
    final nuevos = await Progreso.contarDerrota('llamas');
    expect(nuevos.map((l) => l.id), ['fuego']);
    expect(Progreso.comprados, contains('fuego'));
    // Los trajes de premio no se compran con pescados
    Progreso.monedero = 9999;
    expect(await Progreso.comprar(skins.firstWhere((s) => s.id == 'acido')), isFalse);
  });

  test('Superar el 10-8 da el gato dorado y el mundo secreto el gato hongo', () async {
    await Progreso.completar(Progreso.ultimoPrincipal, 3);
    expect((await Progreso.revisarLogros()).map((l) => l.id), ['campeon']);
    await Progreso.completar(Progreso.ultimoSecreto, 3);
    expect((await Progreso.revisarLogros()).map((l) => l.id), ['hongo']);
  });

  test('Logros nuevos: hielo, ángel, resorte, espinas y arcoíris', () async {
    for (final (tipo, veces, logro) in [
      ('hielo', 5, 'hielo'),
      ('volador', 10, 'angel'),
      ('saltarin', 10, 'resorte'),
      ('espinoso', 5, 'espinas'),
    ]) {
      var nuevos = <String>[];
      for (var i = 0; i < veces; i++) {
        nuevos = (await Progreso.contarDerrota(tipo)).map((l) => l.id).toList();
      }
      expect(nuevos, [logro]);
    }
    await Progreso.completar(Progreso.arcoiris, 5);
    expect((await Progreso.revisarLogros()).map((l) => l.id), ['arcoiris']);
  });

  test('Tiborio y Buterio tienen partidas separadas', () async {
    SharedPreferences.setMockInitialValues({'pescados_0': 4, 'monedero': 50});
    await Progreso.elegirPerfil('tiborio');
    expect(Progreso.completado(0), isTrue, reason: 'la partida de antes es de Tiborio');
    expect(Progreso.monedero, 50);
    await Progreso.elegirPerfil('buterio');
    expect(Progreso.completado(0), isFalse);
    expect(Progreso.monedero, 0);
    await Progreso.completar(3, 2);
    await Progreso.elegirPerfil('tiborio');
    expect(Progreso.completado(3), isFalse);
    await Progreso.elegirPerfil('buterio');
    expect(Progreso.completado(3), isTrue);
  });

  test('La barra llega al 100 % solo con todo y todos los pescados', () async {
    SharedPreferences.setMockInitialValues({});
    await Progreso.elegirPerfil('buterio');
    expect(Progreso.porcentaje(), 0);
    for (var i = 0; i < todosLosNiveles.length; i++) {
      await Progreso.completar(i, Progreso.totalPescados(i) - 1);
    }
    expect(Progreso.porcentaje(), lessThan(100));
    for (var i = 0; i < todosLosNiveles.length; i++) {
      await Progreso.completar(i, Progreso.totalPescados(i));
    }
    expect(Progreso.porcentaje(), closeTo(100, 0.001));
  });
}
