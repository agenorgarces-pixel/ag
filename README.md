# Peluquería móvil

App Flutter que cubre el primer flujo que definimos: registrar un cliente y
agregarle servicios o productos, tal como hacía `registrar_cliente()` en el
script original — pero como una estación móvil más dentro de la red local
del salón.

## Cómo encaja en la arquitectura

Esta app es un cliente delgado: no guarda el catálogo ni el inventario como
fuente de verdad, solo le habla al servidor local del salón (la máquina que
diseñamos como "Servidor local" en el diagrama de arquitectura). Si el WiFi
falla un momento, el registro se guarda en una base SQLite local
(`lib/services/db_helper.dart`) y se reintenta enviar después — así no se
pierde ninguna venta.

## Antes de correrla

1. Instala Flutter (https://docs.flutter.dev/get-started/install).
2. Dentro de la carpeta del proyecto:
   ```
   flutter pub get
   ```
3. Edita `lib/services/api_service.dart` y cambia `baseUrl` por la IP real
   del servidor local dentro de la red del salón, por ejemplo:
   ```dart
   static String baseUrl = 'http://192.168.1.50:8000';
   ```
4. Corre la app en un dispositivo o emulador conectado a la misma red WiFi
   que el servidor:
   ```
   flutter run
   ```

## Lo que falta del lado del servidor

Esta app asume que el servidor local expone dos endpoints (los que
definimos al hablar de la arquitectura):

- `GET /servicios` → devuelve el catálogo actualizado como JSON
  `{ "nombre servicio": precio_o_null, ... }`
- `POST /ventas` → recibe `{ "cliente": "...", "items": [...] }` y guarda el
  registro en la base de datos central.

Si todavía no existe ese backend, puedo ayudarte a construirlo (por ejemplo
en FastAPI o Node) para que esta app tenga con quién hablar.

## Qué sigue

- Pantalla de "Cobrar" (equivalente a `cobrar()` del script).
- Pantalla de inventario y compras.
- Cierre de caja.

Dime cuál de estos flujos quieres que hagamos después.
