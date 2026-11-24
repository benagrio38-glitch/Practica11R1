# RecuParty R1

Tarea 11: vistas completas de la aplicación (Flutter), actualizada con la revisión "Pantallas obligatorias y correcciones al modelo" del docente.

- Alumno: Oscar Manuel Ayala Ortiz
- N.C. 1225100784, grupo GTID244
- Materia: Desarrollo de Aplicaciones Móviles
- Docente: Anastacio Rodríguez García

## 1. Descripción breve

RecuParty R1 es una app para organizar fiestas. El nombre junta "recuperación 1" con "party". Sirve para crear una fiesta, venderle boletos y contratar salones, albercas, DJs y taquizas con proveedores. Los datos son de ejemplo y se guardan en memoria mientras la app está abierta; todavía no hay servidor ni base de datos.

La app es solo para mayores de 18 años. Los precios, lugares y personas son inventados.

## 2. Los 3 tipos de usuario y su navegación

Cada cuenta tiene **un solo rol**. Si una persona quiere organizar y también ser proveedor, crea otra cuenta (perfiles separados). Así lo decidí para la corrección "Rol único o múltiple".

| Usuario | Qué hace | Navegación (barra de abajo) |
|---|---|---|
| Organizador | Crea y publica fiestas, ve sus boletos vendidos, pide cotizaciones y lleva su presupuesto | Inicio, Mis fiestas, Boletos, Servicios (catálogo y mis solicitudes), Presupuesto. El perfil está en el botón con su nombre |
| Invitado | Busca fiestas, compra boletos y consulta sus boletos | Explorar, Mis boletos, Perfil |
| Proveedor | Publica sus servicios y responde o cotiza solicitudes | Inicio, Mis servicios, Solicitudes, Perfil |

Usuarios de prueba (contraseña de todos: `123456`):

- organizador@recuparty.com
- invitado@recuparty.com
- proveedor@recuparty.com

## 3. Pantallas que pidió la revisión

| # | Sección del documento | Pantallas en la app |
|---|---|---|
| 1 | Splash screen | Logo y carga; revisa si hay sesión y manda al dashboard del rol o al login |
| 2 | Acceso y registro | Registro (nombre, correo, contraseña y rol), inicio de sesión, **recuperar acceso** con código y cierre de sesión |
| 3 | Dashboards por rol | Organizador: boletos vendidos vs. invitados esperados, gastos vs. presupuesto, solicitudes abiertas, ingresos y cotizaciones por responder. Invitado: fiestas disponibles, búsqueda y sus boletos. Proveedor: solicitudes nuevas, cotizaciones sin respuesta, servicios publicados y cotizaciones aceptadas |
| 4 | Fiestas | Mis fiestas con filtros por estado y fecha, formulario para crear y **editar**, detalle con publicar, editar y **cancelar** (con política de reembolso), lista pública con búsqueda por nombre/lugar, fecha y precio, y detalle público |
| 5 | Boletos | Compra con **un boleto por asistente**, total antes de confirmar y pago simulado; Mis boletos; **detalle del boleto con QR único**; boletos vendidos para el organizador; **control de acceso** por código (no deja entrar dos veces) |
| 6 | Servicios | Catálogo con búsqueda y filtros por tipo y precio, **detalle de servicio**, formulario para publicar y editar, Mis servicios con **desactivar (baja lógica)** |
| 7 | Solicitudes y cotizaciones | Solicitar servicio (fiesta, fecha requerida y mensaje), **Mis solicitudes**, bandeja del proveedor, **cotizar con precio y comentarios** (con historial de versiones), y el organizador acepta o rechaza la cotización. Estados: pendiente, cotizada, aceptada, rechazada y cancelada |
| 8 | Presupuesto | Resumen por fiesta: presupuesto, servicios aceptados, otros gastos, recaudado y balance; se pueden registrar otros gastos |
| 9 | Perfil | Editar nombre y correo, datos del negocio del proveedor, cambiar contraseña, cerrar sesión y **pedir la eliminación de la cuenta** con confirmación |

No hice en esta versión lo que el documento marca como opcional o fase 2: reportes exportables, notificaciones, reseñas y chat. El control de acceso valida el código del boleto escrito a mano; leerlo con la cámara sería el siguiente paso.

## 4. Correcciones al modelo

El modelo está en `lib/modelos.dart` y las operaciones se movieron a servicios de aplicación en `lib/servicios_app.dart`.

| Problema que marcó el docente | Cómo quedó |
|---|---|
| `Usuario.clave` legible | `passwordHash` + `salt` (SHA-256 repetido, `lib/seguridad.dart`). Nunca se guarda la contraseña |
| Usuario sin id ni estado | `idUsuario`, `estado` (activa / eliminación solicitada), `fechaCreacion` y `actualizadoEn` |
| Rol único o múltiple | Un solo rol por cuenta (perfiles separados) |
| Fecha como texto | `fechaHoraInicio`, `fechaHoraFin` y `zonaHoraria` (America/Mexico_City) |
| Lugar como texto libre | Clase `Lugar` con nombre, dirección, ciudad y coordenadas opcionales. Antes de comprar solo se ve nombre y ciudad |
| Invitados y aforo mezclados | `invitadosEsperados` y `aforoMaximo` separados |
| `vendidos` guardado | Se calcula desde los boletos válidos; disponibles = aforo − vendidos |
| Dinero con `double` | Clase `Dinero` en centavos enteros con moneda MXN |
| Party sin estado ni organizador | `organizadorId`, estados (borrador, publicada, cancelada, finalizada), descripción y edad mínima |
| Boleto sin relaciones ni datos de compra | `partyId`, `compraId`, `compradorId`, `precioUnitario`, `fechaCompra`, `estado` y `codigoAcceso` único |
| Cantidad y asistente incompatibles | Un registro de `Boleto` por asistente |
| Compra y pago no modelados | Entidades `Compra` y `Pago`. El pago solo guarda la terminación de la tarjeta |
| Tipo y disponibilidad del servicio | `TipoServicio` (salón, alberca, DJ, banquete, decoración), `UnidadPrecio` (por evento, hora o persona), `zona`, `disponible`, `activo` y `aprobado` |
| Métodos de edición dentro de entidades | `agregarServicio`, `comprarBoleto`, `iniciarSesion`, etc. ahora están en `ServicioCuentas`, `ServicioFiestas`, `ServicioBoletos`, `ServicioCatalogo`, `ServicioSolicitudes` y `ServicioPresupuesto` |
| Solicitud con estado libre | `EstadoSolicitud` controlado, mensaje, fecha requerida, fecha de creación y relación con fiesta, servicio, organizador y proveedor |
| Versiones de cotización | Lista de `Cotizacion` con versión, precio, comentarios, vigencia y respuesta |
| Presupuesto sin desglose | Entidad `Gasto`; al aceptar una cotización se registra como gasto |

Reglas de seguridad y consistencia: el organizador solo edita sus fiestas, no se vende más que el aforo, no se cambia el precio cuando ya hay ventas, cada boleto tiene un código único que no se reutiliza, los datos de los asistentes solo los ve el organizador, el boleto se cancela hasta 48 horas antes y, si se cancela la fiesta, se reembolsa el 100%.

## 5. Manejo de estado

Usé `ChangeNotifier` con un `InheritedNotifier` (`AppState` y `AppScope` en `lib/estado.dart`), que ya trae Flutter. `AppState` reúne el repositorio en memoria (`lib/repositorio.dart`) y los servicios de aplicación. Cuando algo cambia avisa con `notifyListeners()` y las pantallas se redibujan solas; como está arriba de toda la app, la sesión y los datos no se pierden al navegar.

## 6. Cómo ejecutar la app

```
flutter pub get
flutter analyze
flutter test
flutter run
```

Paquetes nuevos: `crypto` (hash de contraseñas) y `qr_flutter` (QR del boleto).

Las capturas se generan con `flutter test tool/capturas_test.dart --update-goldens` y se copian de `tool/capturas/` a `screenshots/`.

## 7. Demostración al docente

- Dispositivo/emulador usado: laptop Dell con Windows, app corriendo en el navegador Microsoft Edge (`flutter run`, Edge)
- Fecha y modalidad de la demostración: lunes 9 de noviembre de 2026, presencial

## 8. Screenshots

### Splash, acceso y registro
![Splash](screenshots/01-splash.png)
![Login](screenshots/02-login.png)
![Registro](screenshots/03-registro.png)
![Recuperar acceso](screenshots/18-recuperar-acceso.png)

### Organizador
![Dashboard organizador](screenshots/19-dashboard-organizador.png)
![Mis fiestas con filtros](screenshots/20-mis-fiestas.png)
![Editar fiesta](screenshots/21-formulario-fiesta.png)
![Detalle de fiesta](screenshots/22-detalle-fiesta.png)
![Boletos vendidos y control de acceso](screenshots/23-boletos-vendidos.png)
![Catálogo de servicios](screenshots/24-catalogo-servicios.png)
![Detalle de servicio](screenshots/25-detalle-servicio.png)
![Solicitar servicio](screenshots/26-solicitar-servicio.png)
![Mis solicitudes](screenshots/27-mis-solicitudes.png)
![Detalle de solicitud cotizada](screenshots/28-detalle-solicitud-cotizada.png)
![Presupuesto](screenshots/29-presupuesto.png)

### Invitado
![Dashboard invitado](screenshots/31-dashboard-invitado.png)
![Detalle público de fiesta](screenshots/32-detalle-fiesta-publica.png)
![Compra de boletos](screenshots/33-compra-boletos.png)
![Mis boletos](screenshots/34-mis-boletos.png)
![Detalle del boleto con QR](screenshots/35-detalle-boleto.png)

### Proveedor
![Dashboard proveedor](screenshots/36-dashboard-proveedor.png)
![Bandeja de solicitudes](screenshots/37-bandeja-proveedor.png)
![Responder o cotizar](screenshots/38-responder-cotizar.png)
![Mis servicios](screenshots/39-mis-servicios.png)
![Editar servicio](screenshots/40-formulario-servicio.png)

### Perfil
![Perfil](screenshots/30-perfil.png)

### Versión anterior (9 de noviembre)
![Foto del equipo](screenshots/13-foto-equipo.png)
![Navegación: Mis boletos después de comprar](screenshots/14-navegacion.png)
![Solicitudes del proveedor](screenshots/15-solicitudes-proveedor.png)

## 9. Pruebas automáticas

24 pruebas: 3 del splash y login, 14 del dominio y los servicios (dinero exacto, hash de contraseñas, recuperar acceso, aforo, un boleto por asistente, cancelación con reembolso, control de acceso, baja lógica y flujo de cotización) y 7 de pantallas.

![flutter test](screenshots/17-flutter-test.png)
