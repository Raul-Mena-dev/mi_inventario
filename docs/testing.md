# Testing

## Requisitos

- Flutter SDK disponible en el PATH.
- Dependencias instaladas con `flutter pub get`.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
```

## Que cubren los tests actuales

- Lectura del modelo `Product` con `stock`.
- Calculo de totales en `TicketItem`.
- Insercion y lectura de productos en SQLite temporal.
- Descuento de stock al generar ventas.
- Validacion de stock insuficiente.
- Limite de historial de tickets a 5 registros y limpieza de PDFs antiguos.

## Infraestructura de test

Los tests de repositorio usan `sqflite_common_ffi` con una base temporal por test. Esto evita tocar la base real de Android/iOS y permite validar la capa de datos en entorno local/CI.
