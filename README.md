# RecuParty R1

Tarea 11: vistas completas de la aplicación (Flutter).

- Alumno: Oscar Manuel Ayala Ortiz
- N.C. 1225100784, grupo GTID244
- Materia: Desarrollo de Aplicaciones Móviles
- Docente: Anastacio Rodríguez García

## 1. Descripción breve

RecuParty R1 es una app para organizar fiestas. El nombre junta "recuperación 1" con "party". Sirve para crear una fiesta, contratar salones, albercas y DJs, y vender boletos. Los datos son de ejemplo y se guardan en memoria mientras la app está abierta, no hay base de datos.

La app tiene splashscreen, login, registro con validación, tres dashboards, dos listas con datos dinámicos (con estado vacío) y tres formularios.

La app es solo para mayores de 18 años. Los precios y lugares son inventados.

## 2. Los 3 tipos de usuario y sus dashboards

| Usuario | Qué hace | Pestañas del dashboard |
|---|---|---|
| Organizador | Crea parties, cotiza servicios y ve cuántos boletos ha vendido | Resumen, Mis parties, Servicios |
| Invitado | Busca parties y compra boletos | Inicio, Explorar, Mis boletos |
| Proveedor | Publica salones, albercas o DJs y responde solicitudes | Resumen, Mis servicios, Solicitudes |

Usuarios de prueba (contraseña de todos: `123456`):

- organizador@recuparty.com
- invitado@recuparty.com
- proveedor@recuparty.com

También se puede crear una cuenta nueva desde el registro y elegir el rol.

Listas con datos dinámicos y estado vacío:

- Mis parties (organizador), Explorar y Mis boletos (invitado), Mis servicios y Solicitudes (proveedor). Cuando una lista no tiene nada se muestra un mensaje de "No hay ...". Se ve con una cuenta recién registrada.

Formularios del dominio:

- Nueva party (organizador): nombre, fecha, lugar, invitados, presupuesto y precio del boleto.
- Comprar boletos (invitado): nombre del asistente y cantidad.
- Nuevo servicio (proveedor): tipo, nombre, precio y descripción.

Flujo para probar todo: el organizador cotiza un servicio, el proveedor lo acepta o lo rechaza, y el invitado compra boletos de una party.

## 3. Manejo de estado elegido (y por qué)

Usé `ChangeNotifier` con un `InheritedNotifier` (la clase `AppState` y el widget `AppScope` en `lib/estado.dart`). Es el manejo de estado que ya trae Flutter, así que no hace falta instalar paquetes.

- `AppState` guarda al usuario que inició sesión, las parties, los servicios, los boletos y las solicitudes.
- Cuando algo cambia, `AppState` avisa con `notifyListeners()` y las pantallas que lo usan se redibujan solas.
- `AppScope` está arriba de toda la app, por eso el estado (rol, datos, listas) no se pierde al navegar entre pantallas.

Lo elegí porque es sencillo, es fácil de explicar y la app no necesita algo más grande por ahora. Más adelante se puede cambiar a Cubit/BLoC.

## 4. Cómo ejecutar la app

```
flutter pub get
flutter analyze
flutter run
```

El código está en `lib/`: `main.dart`, `modelos.dart`, `estado.dart`, `widgets_comunes.dart` y la carpeta `pantallas/`.

## 5. Demostración al docente

- Dispositivo/emulador usado: COMPLETAR
- Fecha y modalidad de la demostración: COMPLETAR

## 6. Screenshots

### Splashscreen
![Splash](screenshots/01-splash.png)

### Autenticación
![Login](screenshots/02-login.png)
![Registro](screenshots/03-registro.png)

### Dashboards
![Dashboard Organizador](screenshots/04-dashboard-organizador.png)
![Dashboard Invitado](screenshots/05-dashboard-invitado.png)
![Dashboard Proveedor](screenshots/06-dashboard-proveedor.png)

### Listas
![Lista principal](screenshots/07-lista-principal.png)
![Lista secundaria](screenshots/08-lista-secundaria.png)
![Estado vacío](screenshots/09-lista-vacia.png)

### Formularios
![Formulario nueva party](screenshots/10-formulario-party.png)
![Formulario comprar boletos](screenshots/11-formulario-boletos.png)
![Formulario nuevo servicio](screenshots/12-formulario-servicio.png)

### Evidencia funcional
![Foto del equipo](screenshots/13-foto-equipo.png)
![Navegación: Mis boletos después de comprar](screenshots/14-navegacion.png)
![Solicitudes del proveedor](screenshots/15-solicitudes-proveedor.png)
![Dashboard del organizador con datos](screenshots/16-dashboard-organizador-ana.png)
