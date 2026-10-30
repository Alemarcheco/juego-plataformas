import 'package:flutter_test/flutter_test.dart';
import 'package:paco_aventuras/datos/logros.dart';
import 'package:paco_aventuras/datos/skins.dart';
import 'package:paco_aventuras/progreso.dart';

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
}
