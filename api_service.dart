import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../data/catalogo_inicial.dart';
import 'db_helper.dart';

/// Habla con el servidor local del salón (el mismo que diseñamos en la
/// arquitectura: una máquina dentro de la red WiFi/Ethernet del local, NO en
/// internet). Si la petición falla por cualquier motivo de red, los métodos
/// devuelven un resultado que le indica a la pantalla que debe guardar el
/// registro localmente en vez de perderlo.
class ApiService {
  /// Cambiar esto por la IP real del servidor local dentro de la red del
  /// salón (ej. la de la máquina de "Servidor local" del diagrama).
  static String baseUrl = 'http://192.168.1.50:8000';

  static const Duration _timeout = Duration(seconds: 4);

  /// Intenta traer el catálogo actualizado del servidor. Si no hay conexión,
  /// cae de vuelta al catálogo local de respaldo (catalogo_inicial.dart).
  static Future<Map<String, double?>> obtenerServicios() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/servicios'))
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(resp.body);
        return data.map((k, v) => MapEntry(k, (v as num?)?.toDouble()));
      }
    } catch (_) {
      // Sin conexión con el servidor: usamos el catálogo local de respaldo.
    }
    return serviciosInicial;
  }

  /// Envía el registro de un cliente (servicios y/o productos) al servidor.
  /// Devuelve true si se envió con éxito, false si hubo que guardarlo
  /// localmente para reintentar después.
  static Future<bool> enviarVenta(
    String cliente,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/ventas'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'cliente': cliente, 'items': items}),
          )
          .timeout(_timeout);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return true;
      }
      // El servidor respondió pero con error: igual lo guardamos localmente
      // para no perder el registro, y se puede reintentar más tarde.
      await DbHelper.instancia.guardarPendiente(cliente, items);
      return false;
    } on SocketException {
      await DbHelper.instancia.guardarPendiente(cliente, items);
      return false;
    } catch (_) {
      await DbHelper.instancia.guardarPendiente(cliente, items);
      return false;
    }
  }

  /// Recorre los registros pendientes guardados localmente e intenta
  /// reenviarlos. Llamar esto al abrir la app o cuando el usuario presiona
  /// "sincronizar".
  static Future<int> sincronizarPendientes() async {
    final pendientes = await DbHelper.instancia.obtenerPendientes();
    int enviados = 0;

    for (final pendiente in pendientes) {
      final cliente = pendiente['cliente'] as String;
      final items = List<Map<String, dynamic>>.from(
        jsonDecode(pendiente['items_json'] as String),
      );

      try {
        final resp = await http
            .post(
              Uri.parse('$baseUrl/ventas'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'cliente': cliente, 'items': items}),
            )
            .timeout(_timeout);

        if (resp.statusCode == 200 || resp.statusCode == 201) {
          await DbHelper.instancia.eliminarPendiente(pendiente['id'] as int);
          enviados++;
        }
      } catch (_) {
        // Seguimos sin conexión: dejamos este pendiente para el próximo intento.
        break;
      }
    }
    return enviados;
  }
}
