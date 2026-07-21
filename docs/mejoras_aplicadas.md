# Mejoras aplicadas

Fecha: 2026-05-23

## Cambios funcionales

- Se agrego control de stock al modelo `Product`, al formulario y a la base SQLite.
- Se agrego migracion de base de datos a version 2 para instalaciones existentes.
- Los tickets ahora usan cantidades reales con `TicketItem`.
- El PDF del ticket muestra producto, cantidad, precio unitario, subtotal y total correcto.
- Al generar un ticket se valida stock disponible y se descuentan existencias.
- La pantalla principal muestra stock y agrega busqueda por nombre, descripcion o subcategoria.
- El catalogo PDF ahora muestra stock y omite redes sociales vacias.
- El historial de tickets permite abrir y compartir PDFs.
- Se agrego historial de movimientos de inventario.
- Se registran entradas, ajustes manuales y ventas como movimientos.
- Se agregaron alertas y filtro de stock bajo en la pantalla principal.

## Cambios de confiabilidad

- Imagenes de productos y logo se copian al almacenamiento interno de la app.
- Se agregaron validaciones de precio y existencia.
- Se liberan `TextEditingController` en formularios y configuracion.
- Se evita acumular listeners dentro del autocomplete.
- Se valida que imagenes existan antes de mostrarlas.
- Se eliminan PDFs antiguos cuando el historial supera el limite actual.
- Se agregaron permisos Android mas adecuados para Android 13+ y se conservan permisos iOS existentes.

## Pruebas

- Se reemplazo la prueba inicial de contador por pruebas de modelo y calculo de ticket.
- Se agrego `sqflite_common_ffi` para probar repositorios SQLite fuera de Android/iOS.
- Se agrego infraestructura de base temporal en `test/test_database.dart`.
- Se agregaron pruebas para `ProductRepository` y `TicketRepository`.
- Se extendieron pruebas para movimientos de inventario, ajustes de stock y productos con stock bajo.

## Pendiente de verificacion local

Esta terminal no tiene `flutter` ni `dart` disponibles en el PATH, por lo que queda pendiente ejecutar:

```bash
flutter analyze
flutter test
```
