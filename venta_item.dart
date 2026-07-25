/// Representa un ítem dentro del registro de un cliente:
/// un servicio (ej. "Corte dama medio") o un producto (ej. "2 x Esmalte").
class VentaItem {
  final String item;
  final String tipo; // 'Servicio' o 'Producto'
  final double valor;

  VentaItem({
    required this.item,
    required this.tipo,
    required this.valor,
  });

  Map<String, dynamic> toJson() => {
        'item': item,
        'tipo': tipo,
        'valor': valor,
      };

  factory VentaItem.fromJson(Map<String, dynamic> json) => VentaItem(
        item: json['item'] as String,
        tipo: json['tipo'] as String,
        valor: (json['valor'] as num).toDouble(),
      );
}
