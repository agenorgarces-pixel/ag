import 'package:flutter/material.dart';
import '../data/catalogo_inicial.dart';
import '../models/venta_item.dart';
import '../services/api_service.dart';
import '../services/db_helper.dart';

class RegistrarClienteScreen extends StatefulWidget {
  const RegistrarClienteScreen({super.key});

  @override
  State<RegistrarClienteScreen> createState() => _RegistrarClienteScreenState();
}

class _RegistrarClienteScreenState extends State<RegistrarClienteScreen> {
  final _nombreController = TextEditingController();
  final List<VentaItem> _items = [];

  Map<String, double?> _catalogoServicios = serviciosInicial;
  int _pendientesSinSincronizar = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final servicios = await ApiService.obtenerServicios();
    final pendientes = await DbHelper.instancia.contarPendientes();
    setState(() {
      _catalogoServicios = servicios;
      _pendientesSinSincronizar = pendientes;
      _cargando = false;
    });
  }

  double get _total => _items.fold(0, (suma, item) => suma + item.valor);

  Future<void> _agregarServicio() async {
    final seleccionado = await showDialog<MapEntry<String, double?>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Elegir servicio'),
        children: _catalogoServicios.entries.map((entrada) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, entrada),
            child: Text(
              entrada.value != null
                  ? '${entrada.key} — \$${entrada.value!.toStringAsFixed(0)}'
                  : '${entrada.key} — sin precio definido',
            ),
          );
        }).toList(),
      ),
    );

    if (seleccionado == null) return;

    double precio = seleccionado.value ?? 0;
    if (seleccionado.value == null) {
      precio = await _pedirPrecioManual(seleccionado.key) ?? 0;
      if (precio <= 0) return;
    }

    setState(() {
      _items.add(VentaItem(item: seleccionado.key, tipo: 'Servicio', valor: precio));
    });
  }

  Future<void> _agregarProducto() async {
    final seleccionado = await showDialog<MapEntry<String, ProductoInicial>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Elegir producto'),
        children: inventarioInicial.entries.map((entrada) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, entrada),
            child: Text(
              '${entrada.key} — \$${entrada.value.precio.toStringAsFixed(0)} '
              '(stock: ${entrada.value.cantidad})',
            ),
          );
        }).toList(),
      ),
    );

    if (seleccionado == null) return;

    final cantidad = await _pedirCantidad(seleccionado.value.cantidad);
    if (cantidad == null || cantidad <= 0) return;

    setState(() {
      _items.add(VentaItem(
        item: '$cantidad x ${seleccionado.key}',
        tipo: 'Producto',
        valor: cantidad * seleccionado.value.precio,
      ));
    });
  }

  Future<double?> _pedirPrecioManual(String nombreServicio) async {
    final controlador = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Precio para "$nombreServicio"'),
        content: TextField(
          controller: controlador,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '\$'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controlador.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<int?> _pedirCantidad(int stockDisponible) async {
    final controlador = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cantidad (disponible: $stockDisponible)'),
        content: TextField(
          controller: controlador,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controlador.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarRegistro() async {
    if (_nombreController.text.trim().isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta el nombre del cliente o no hay ítems agregados.')),
      );
      return;
    }

    final cliente = _nombreController.text.trim();
    final items = _items.map((i) => i.toJson()).toList();

    final enviado = await ApiService.enviarVenta(cliente, items);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enviado
              ? 'Registro enviado al servidor.'
              : 'Sin conexión con el servidor: guardado localmente, se enviará cuando haya red.',
        ),
      ),
    );

    final pendientes = await DbHelper.instancia.contarPendientes();
    setState(() {
      _nombreController.clear();
      _items.clear();
      _pendientesSinSincronizar = pendientes;
    });
  }

  Future<void> _sincronizarAhora() async {
    final enviados = await ApiService.sincronizarPendientes();
    final pendientes = await DbHelper.instancia.contarPendientes();
    if (!mounted) return;
    setState(() => _pendientesSinSincronizar = pendientes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$enviados registro(s) sincronizado(s).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar cliente'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar pendientes',
            icon: Badge(
              label: Text('$_pendientesSinSincronizar'),
              isLabelVisible: _pendientesSinSincronizar > 0,
              child: const Icon(Icons.sync),
            ),
            onPressed: _sincronizarAhora,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del cliente',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _agregarServicio,
                          icon: const Icon(Icons.content_cut),
                          label: const Text('Servicio'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _agregarProducto,
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Producto'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _items.isEmpty
                        ? const Center(child: Text('Aún no hay ítems agregados.'))
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return ListTile(
                                title: Text(item.item),
                                subtitle: Text(item.tipo),
                                trailing: Text('\$${item.valor.toStringAsFixed(0)}'),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 18)),
                      Text(
                        '\$${_total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _guardarRegistro,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Guardar registro'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
