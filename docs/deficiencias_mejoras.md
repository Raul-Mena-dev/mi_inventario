# Documento de deficiencias y mejoras - Mi Inventario

Fecha de analisis: 2026-05-23

> Nota: varias recomendaciones de este documento ya fueron implementadas.
> Consulta `docs/mejoras_aplicadas.md` para ver el estado actualizado de los cambios.

## Resumen ejecutivo

La aplicacion ya cubre un flujo util para pequenos negocios: registrar productos, organizar inventario, generar catalogos PDF y emitir tickets. Las mejoras mas importantes estan en confiabilidad de datos, correccion del flujo de tickets, validaciones, manejo de imagenes, pruebas y preparacion para crecimiento.

## Deficiencias principales

### 1. El ticket no respeta cantidades seleccionadas

En `TicketScreen` el usuario puede aumentar o disminuir cantidades, pero al generar el PDF se envia solo una lista de productos:

`selectedItems.map((t) => t.product).toList()`

Esto provoca que `TicketPDFService` calcule y muestre el ticket como si cada producto seleccionado tuviera cantidad 1. El total en pantalla puede no coincidir con el total del PDF ni con el historial.

Impacto: alto. Afecta directamente ventas, cobros y confianza del usuario.

Mejora recomendada:

- Cambiar `TicketPDFService.generateTicket` para recibir `List<TicketItem>`.
- Imprimir cantidad, precio unitario y subtotal.
- Guardar en historial el total calculado desde los `TicketItem`.

### 2. La app no maneja stock real

Aunque se llama inventario, el modelo `Product` no tiene existencia, cantidad disponible, entradas, salidas ni alerta de bajo stock. Actualmente funciona mas como catalogo de productos y generador de tickets.

Impacto: alto si el objetivo es control de inventario.

Mejora recomendada:

- Agregar campo `stock` al producto.
- Descontar stock al emitir ticket.
- Registrar movimientos de inventario.
- Agregar alertas de stock bajo.
- Permitir ajustes manuales con motivo.

### 3. Persistencia de imagenes fragil

La app guarda `imagePath` y `logoPath` apuntando al archivo seleccionado por el usuario. Si el archivo se mueve, se borra o cambia de permisos, la imagen deja de funcionar.

Impacto: medio/alto. Puede romper visualmente catalogos, productos y logo.

Mejora recomendada:

- Copiar imagenes al directorio de documentos de la aplicacion.
- Guardar rutas internas controladas por la app.
- Eliminar imagenes internas cuando se borren productos, si ya no se usan.

### 4. No existen migraciones de base de datos

`DBHelper` abre la base con `version: 1` y solo define `onCreate`. Si se agregan columnas como `stock`, codigo SKU o impuestos, las instalaciones existentes no recibiran cambios sin una migracion.

Impacto: alto para evolucionar la app sin perdida de datos.

Mejora recomendada:

- Implementar `onUpgrade`.
- Versionar cambios de esquema.
- Crear pruebas de migracion basicas.

### 5. Validacion insuficiente de datos

El formulario requiere nombre y precio, pero:

- Precio invalido se convierte silenciosamente en `0`.
- Categoria y subcategoria pueden quedar vacias.
- No se valida que el precio sea positivo.
- No se normalizan categorias repetidas con espacios o mayusculas distintas.

Impacto: medio. Genera datos inconsistentes y catalogos confusos.

Mejora recomendada:

- Validar precio numerico y mayor o igual a cero.
- Mostrar error si el precio no se puede convertir.
- Decidir si categoria/subcategoria deben ser obligatorias.
- Normalizar espacios y capitalizacion.

### 6. Prueba automatica desactualizada

`test/widget_test.dart` conserva la prueba base del contador de Flutter. La app ya no es un contador, por lo que esa prueba no valida el comportamiento real y probablemente falla.

Impacto: medio. Reduce confianza para cambiar codigo.

Mejora recomendada:

- Reemplazarla por pruebas de carga de pantalla principal.
- Agregar pruebas de repositorios con base temporal.
- Agregar pruebas del calculo de tickets.
- Agregar pruebas de validacion del formulario.

### 7. Riesgo de errores por uso de nulos donde el modelo no es nullable

El modelo `Product` declara campos como `name` y `price` no nulos, pero hay codigo que los trata como nulos:

- `p.name ?? ''`
- `p.price?.toStringAsFixed(2)`
- `product.price ?? 0`

Impacto: medio. Puede generar advertencias o errores de analisis dependiendo de la configuracion del SDK y dificulta entender el contrato real del modelo.

Mejora recomendada:

- Mantener `Product` no nullable y quitar operadores nulos innecesarios.
- O cambiar el modelo para admitir nulos de forma consistente, si de verdad se esperan.

### 8. Lectura sincrona de archivos durante construccion de UI/PDF

Se usan operaciones como `File.existsSync()` en widgets y `readAsBytesSync()` al generar PDFs. En archivos grandes o dispositivos lentos, esto puede bloquear la interfaz.

Impacto: medio.

Mejora recomendada:

- Preparar datos de imagen antes de construir el PDF.
- Usar lecturas asincronas.
- Cachear validacion de imagenes cuando sea razonable.

### 9. Controladores no liberados

Pantallas como `ProductForm` y `SettingsScreen` crean varios `TextEditingController`, pero no implementan `dispose()`.

Impacto: bajo/medio. Puede causar fugas pequenas de memoria y comportamiento acumulado si la pantalla se abre muchas veces.

Mejora recomendada:

- Implementar `dispose()` y llamar `.dispose()` en cada controlador.

### 10. Autocomplete agrega listeners dentro de `build`

En `ProductForm._buildAutocompleteField`, se agrega un listener al `textEditingController` dentro del `fieldViewBuilder`. Si el widget se reconstruye varias veces, pueden acumularse listeners.

Impacto: medio. Puede producir actualizaciones repetidas o comportamiento dificil de depurar.

Mejora recomendada:

- Sincronizar controladores de forma controlada.
- Evitar agregar listeners dentro de builds repetidos.
- Considerar campos de texto normales con sugerencias propias si el flujo crece.

### 11. Historial limitado y limpieza incompleta

`TicketRepository` conserva solo 5 tickets en la tabla, pero no elimina los archivos PDF asociados a registros antiguos. Ademas, el limite fijo puede ser insuficiente para negocios con ventas frecuentes.

Impacto: medio.

Mejora recomendada:

- Hacer configurable el limite de historial.
- Eliminar PDFs antiguos si se elimina su registro.
- Agregar busqueda por fecha o total.

### 12. Catalogo PDF muestra redes sociales aunque esten vacias

`SettingsService.getSocialLinks()` siempre devuelve un mapa con todas las redes, aunque sus valores sean cadenas vacias. En `PdfService`, el catalogo puede imprimir entradas vacias.

Impacto: bajo/medio. Afecta presentacion del catalogo.

Mejora recomendada:

- Filtrar `socialLinks.entries.where((e) => e.value.trim().isNotEmpty)`.

### 13. Dependencias y widgets sin uso claro

Se observa `share_plus` declarado, pero no se usa en los archivos revisados. Tambien existe `ProductCard`, aunque `HomeScreen` construye su propia lista de productos directamente.

Impacto: bajo. Aumenta ruido y mantenimiento.

Mejora recomendada:

- Usar `share_plus` para compartir PDFs o quitar la dependencia.
- Reutilizar `ProductCard` o eliminarlo si ya no forma parte del diseno.

### 14. Compatibilidad multiplataforma incompleta

El proyecto contiene carpetas de Android, iOS, web, macOS, Linux y Windows. Sin embargo, dependencias como `sqflite`, `image_picker` y manejo de archivos pueden requerir configuracion adicional o alternativas para escritorio/web.

Impacto: variable. Alto si se quiere distribuir fuera de Android/iOS.

Mejora recomendada:

- Definir plataformas objetivo reales.
- Validar permisos y compatibilidad por plataforma.
- Considerar `sqflite_common_ffi` para escritorio.

## Mejoras funcionales sugeridas

### Prioridad alta

1. Corregir tickets con cantidades reales.
2. Agregar control de stock si la app sera inventario y no solo catalogo.
3. Implementar migraciones de base de datos.
4. Validar correctamente precio, categorias y campos obligatorios.
5. Reemplazar la prueba de contador por pruebas reales.

### Prioridad media

1. Copiar imagenes a almacenamiento interno de la app.
2. Agregar busqueda de productos en el inventario principal.
3. Permitir ordenar por nombre, categoria, precio o fecha de creacion.
4. Mejorar historial de tickets con filtros, busqueda y mas registros.
5. Agregar compartir PDF por WhatsApp/correo usando `share_plus`.
6. Agregar confirmacion visual cuando se genere un PDF.

### Prioridad baja

1. Unificar componentes visuales reutilizables.
2. Agregar tema visual centralizado.
3. Limpiar comentarios temporales y `print`.
4. Revisar nombres, formato y consistencia de codigo.

## Propuesta de hoja de ruta

### Fase 1: Correccion y estabilidad

- Corregir tickets para usar `TicketItem`.
- Corregir prueba base de Flutter.
- Agregar `dispose()` a controladores.
- Quitar operadores nulos innecesarios.
- Filtrar redes sociales vacias en PDFs.

### Fase 2: Inventario real

- Agregar campo `stock`.
- Crear migracion de SQLite.
- Descontar stock al generar ticket.
- Agregar movimientos de inventario.
- Agregar alerta de stock bajo.

### Fase 3: Experiencia de negocio

- Compartir catalogos y tickets.
- Mejorar historial de tickets.
- Agregar busqueda avanzada.
- Agregar exportacion por rango/categoria.
- Mejorar diseno y consistencia visual.

### Fase 4: Preparacion para produccion

- Definir plataformas soportadas.
- Revisar permisos de camara/galeria/archivos.
- Agregar pruebas unitarias y widget tests.
- Agregar manejo centralizado de errores.
- Evaluar respaldos/importacion/exportacion de datos.

## Verificacion pendiente

No se pudo ejecutar `flutter analyze` porque `flutter` no esta disponible en el PATH de la terminal usada para esta revision. Conviene ejecutar localmente:

```bash
flutter analyze
flutter test
```

Esos comandos deberian confirmar advertencias, errores de compilacion y pruebas fallidas antes de priorizar cambios.
