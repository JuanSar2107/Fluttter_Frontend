# aviation_inventory

Aplicación Flutter para inventario de piezas de aviación.

## Despliegue web con Docker y Coolify

El `Dockerfile` compila la versión web de Flutter y la sirve con Nginx. En Coolify,
crea una aplicación desde este repositorio, selecciona **Docker Compose** como
estrategia de build y usa `docker-compose.yml` en la raíz. Configura el dominio
para el servicio `web` en el puerto interno **8044** y despliega. Coolify añadirá
el enrutamiento del proxy para el dominio configurado.

## Ejecución local

Requiere Docker Engine con el plugin Docker Compose y Python 3.9 o superior.
El compose local publica la aplicación solo en `localhost`; Coolify usa el
compose principal sin reservar un puerto del servidor.

```bash
python3 run.py up
```

Abre <http://localhost:8044>. Para elegir otro puerto local, establece `APP_PORT`
(por ejemplo, `APP_PORT=9000 python3 run.py up`). También están disponibles:

```bash
python3 run.py logs
python3 run.py status
python3 run.py down
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
