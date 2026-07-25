/// Copia local de respaldo del catálogo de servicios y productos.
///
/// El servidor local es la fuente de verdad real: al abrir la app se intenta
/// descargar el catálogo actualizado (ver ApiService.obtenerCatalogo). Esta
/// lista solo se usa como respaldo si no hay conexión con el servidor todavía
/// (por ejemplo, el primer uso del día antes de conectar al WiFi del salón).
///
/// Los valores en null representan servicios cuyo precio se define caso a
/// caso, igual que en el script original.
const Map<String, double?> serviciosInicial = {
  'cepillado corto': 20000,
  'cepillado medio': 30000,
  'cepillado largo': 40000,
  'cepillado extra largo': 50000,
  'corte dama poco': 20000,
  'corte dama medio': 30000,
  'corte dama abundante': 40000,
  'color base': 30000,
  'aplicacion de tintura': 30000,
  'colorimetria': null,
  'manos tradicional': 20000,
  'pies tradicional': 22000,
  'manos semi permanentes': 35000,
  'pies semi permanentes': 35000,
  'uñas acrilicas': 90000,
  'depilacion cejas cera': 20000,
  'laminado de cejas': 50000,
  'pestaña volumen ruso': 40000,
  'keratina': 100000,
};

class ProductoInicial {
  final double precio;
  final int cantidad;
  const ProductoInicial({required this.precio, required this.cantidad});
}

const Map<String, ProductoInicial> inventarioInicial = {
  'esmalte': ProductoInicial(precio: 8000, cantidad: 50),
  'crema capilar': ProductoInicial(precio: 15000, cantidad: 30),
  'cabello natural': ProductoInicial(precio: 120000, cantidad: 10),
  'alizante': ProductoInicial(precio: 70000, cantidad: 4),
};
