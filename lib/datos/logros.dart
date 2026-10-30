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
];
