# Documento de funcionalidad - Mi Inventario

Fecha de analisis: 2026-05-23

## Resumen del proyecto

Mi Inventario es una aplicacion Flutter orientada a pequenos negocios que necesitan registrar productos, organizarlos por categoria/subcategoria, generar catalogos PDF y emitir tickets digitales simples. La app usa SQLite para guardar productos y tickets, SharedPreferences para configuracion del negocio, ImagePicker para fotografias/logos y servicios PDF para generar documentos locales.

## Tecnologias principales

- Flutter / Dart para la interfaz movil y multiplataforma.
- SQLite mediante `sqflite` para persistencia local.
- `shared_preferences` para datos simples de configuracion.
- `image_picker` para capturar o seleccionar imagenes.
- `pdf`, `path_provider` y `open_file` para crear, guardar y abrir PDFs.
- `share_plus` esta declarado como dependencia, aunque actualmente no se observa uso directo en el codigo revisado.

## Estructura funcional

### Inicio y navegacion

El punto de entrada esta en `lib/main.dart`. La aplicacion carga `HomeScreen` como pantalla principal, con tema Material y titulo "Inventario".

Desde la pantalla principal el usuario puede:

- Ver el nombre y logo del negocio.
- Filtrar productos por categoria.
- Consultar productos agrupados por categoria.
- Crear productos nuevos.
- Editar productos existentes.
- Eliminar productos mediante pulsacion larga y confirmacion.
- Abrir la configuracion del negocio.
- Exportar catalogos PDF.
- Generar tickets digitales.
- Ver el historial reciente de tickets.
- Ver movimientos de inventario.
- Detectar productos con stock bajo.

### Gestion de productos

Los productos se representan con el modelo `Product`, que contiene:

- `id`
- `name`
- `description`
- `price`
- `stock`
- `category`
- `subcategory`
- `imagePath`

La pantalla `ProductForm` permite crear o editar productos. Incluye campos de nombre, descripcion, precio, existencia, categoria, subcategoria e imagen. Para la imagen, el usuario puede tomar una foto con la camara o elegir una desde la galeria.

Las categorias y subcategorias se sugieren con campos de autocompletado basados en los valores ya guardados en la base de datos.

### Almacenamiento de productos

`DBHelper` crea una base local llamada `inventory.db`. La tabla `products` guarda los datos del producto y la ruta local de la imagen.

`ProductRepository` concentra las operaciones principales:

- Insertar producto.
- Consultar todos los productos.
- Actualizar producto.
- Eliminar producto.
- Obtener categorias unicas.
- Obtener subcategorias por categoria.
- Validar y descontar stock.
- Consultar productos con stock bajo.

### Movimientos de inventario

La app registra movimientos de inventario en la tabla `inventory_movements`.
Cada movimiento guarda:

- Producto.
- Cambio de cantidad.
- Stock final.
- Motivo.
- Fecha de creacion.

Se registran movimientos cuando:

- Se crea un producto con existencia inicial.
- Se edita manualmente la existencia de un producto.
- Se genera una venta y se descuenta stock.

`InventoryMovementsScreen` muestra el historial de movimientos, diferenciando entradas y salidas.

### Vista principal del inventario

`HomeScreen` carga los productos desde SQLite y los agrupa por categoria. La interfaz muestra cada categoria como un `ExpansionTile`. Dentro de cada grupo se listan los productos con nombre, precio, icono/imagen y accion de edicion.

Si un producto tiene imagen valida, se muestra una miniatura. Al tocarla se abre `ImageViewerScreen`, que permite verla en pantalla completa con zoom mediante `InteractiveViewer`.

Cuando hay productos con existencia menor o igual a 3, la pantalla principal muestra una alerta de stock bajo y permite filtrar esos productos.

### Configuracion del negocio

`SettingsScreen` permite guardar:

- Nombre del negocio.
- Logo.
- Facebook.
- Instagram.
- TikTok.
- X/Twitter.
- WhatsApp.

Estos datos se almacenan con `SettingsService` en `SharedPreferences`. El nombre y logo se usan en la pantalla principal y en los PDFs. Las redes sociales se imprimen como texto en catalogos y tickets.

### Exportacion de catalogo PDF

`ExportOptionsSheet` muestra las categorias y subcategorias disponibles para que el usuario elija que partes del inventario exportar.

Al confirmar, `PdfService.generateProductPdf` genera un catalogo con:

- Logo del negocio, si existe.
- Nombre del negocio.
- Titulo del catalogo.
- Productos agrupados por categoria y subcategoria.
- Imagen, nombre, descripcion y precio de cada producto.
- Redes sociales del negocio.

El PDF se guarda en el directorio de documentos de la aplicacion con nombre tipo `catalogo_<fecha>.pdf` y se abre automaticamente.

### Tickets digitales

`TicketScreen` permite buscar productos, filtrarlos por categoria y seleccionar cantidades usando botones de suma/resta. La pantalla calcula un total con base en los productos seleccionados.

Al generar el ticket, `TicketPDFService` crea un PDF en formato recibo (`roll57`) con:

- Logo del negocio.
- Nombre del negocio.
- Fecha.
- Tabla de productos.
- Total.
- Redes sociales.
- Mensaje de agradecimiento.

El PDF se guarda localmente y se abre automaticamente. Al generar el ticket se valida el stock disponible y se descuentan existencias.

### Historial de tickets

Los tickets se guardan en la tabla `tickets`, con:

- `id`
- `date`
- `total`
- `pdfPath`

`TicketRepository` conserva solo los 5 tickets mas recientes en la base de datos. `TicketHistoryScreen` lista esos tickets y permite abrir el PDF asociado.

## Flujo principal de uso

1. El usuario entra a la app y configura nombre, logo y redes del negocio.
2. Registra productos con nombre, precio, categoria, subcategoria e imagen opcional.
3. Consulta el inventario desde la pantalla principal, filtrando por categoria si lo necesita.
4. Exporta un catalogo PDF seleccionando categorias/subcategorias.
5. Genera tickets digitales seleccionando productos y cantidades.
6. Consulta los ultimos tickets desde el historial.

## Datos persistidos

- Productos: SQLite, tabla `products`.
- Tickets recientes: SQLite, tabla `tickets`.
- Movimientos de inventario: SQLite, tabla `inventory_movements`.
- Configuracion del negocio: SharedPreferences.
- PDFs generados: directorio de documentos de la aplicacion.
- Imagenes y logo: se guarda la ruta del archivo seleccionado, no una copia controlada por la app.

## Estado de pruebas y verificacion

Se intento ejecutar `flutter analyze`, pero el comando `flutter` no esta disponible en el PATH de esta terminal. La revision se realizo mediante lectura estatica del codigo.

El archivo `test/widget_test.dart` conserva la prueba inicial de contador generada por Flutter, pero esa prueba no corresponde a la funcionalidad actual de la aplicacion.
