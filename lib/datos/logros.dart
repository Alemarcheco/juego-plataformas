/// Un logro: al conseguirlo se gana un traje de premio.
class Logro {
  final String id;
  final String nombre;
  final String descripcion;
  final int meta;

  /// Traje que se gana (id de la lista de skins).
  final String skin;

  const Logro(this.id, this.nombre, this.descripcion, this.meta, this.skin);
}

const List<Logro> logros = [
  Logro('fuego', 'Apagafuegos', 'Elimina 10 perros de fuego.', 10, 'fuego'),
  Logro('acido', 'A prueba de ácido', 'Derrota 5 perros de ácido.', 5, 'acido'),
  Logro('campeon', 'Campeón', 'Supera los 10 mundos principales.', 1, 'dorado'),
  Logro('hongo', 'Explorador gigante', 'Supera el mundo secreto.', 1, 'hongo'),
  Logro('hielo', 'Rompehielos', 'Derrota 5 perros de hielo.', 5, 'hielo'),
  Logro('angel', 'Cazanubes', 'Derrota 10 perros voladores.', 10, 'angel'),
  Logro('resorte', 'Saltamontes', 'Derrota 10 perros que saltan.', 10, 'resorte'),
  Logro('espinas', 'Sin pincharse', 'Derrota 5 perros de espinas.', 5, 'espinas'),
  Logro('arcoiris', 'El secreto de la playa', 'Completa el nivel secreto del 3-3.', 1, 'arcoiris'),
];

/// Enemigos que cuentan para los logros (nombre del tipo de enemigo).
const enemigosDeLogros = ['llamas', 'acido', 'hielo', 'volador', 'saltarin', 'espinoso'];
