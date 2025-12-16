# Virtual-Transfermovil-Test - Transfermovil REST API Emulator (Versión Personalizada)

Transfermovil is a closed API, which makes development of applications really painful. To overcome such limitations this repo holds a virtual (does not involves money) implementation of such API. Esta versión incluye ajustes para compatibilidad con GLib 2.72 y soporte para Docker.

## Requirements

VirtualTM is written in Vala, so make sure to have a compiler at the ready:

  * [valac](https://vala.dev/) (= 0.56)

VirtualTM uses:

  * [gio-2.0](https://gitlab.gnome.org/GNOME/glib) (>= 2.72) - Ajustado para compatibilidad
  * [glib-2.0](https://gitlab.gnome.org/GNOME/glib) (>= 2.72)
  * [gobject-2.0](https://gitlab.gnome.org/GNOME/glib) (>= 2.72)
  * [json-glib-1.0](https://gitlab.gnome.org/GNOME/json-glib) (>= 1.8)
  * [soup-3.0](https://gitlab.gnome.org/GNOME/libsoup) (>= 3.4.3)
  * [SQLite3](https://www.sqlite.org/index.html) (>= 3.37.2)

VirtualTM components comunicates over DBus so make sure to have one of those. It also uses a SQLite database (of course) called **virtualtm.db** by default, although you can use any other, just pass it using -d option to server instance.

## How to use it

VirtualTM consists of two components: a server and a command line utility. The server works on the background and listens to incoming REST API requests, stores them in a database, and notifies clients when the payment is completed. The command line utility on the other hand controls server instance by two main methods: listing pending (not payed - virtually) payments, and paying those payments (again, **virtually**). And that's it.

## Limitations

VirtualTM is a in-a-hurry kind of application. It means it was not meant for production environment, nor for performance. It is also full synchronous, which means a request at a time, a command line interaction at a time (exclusive).

By the way, you must create the database on your own, so have fun. Here is the code to create the needed table:

```SQL
  CREATE TABLE "Payment" (
    "Id"	INTEGER NOT NULL,
    "Amount"	REAL NOT NULL,
    "Currency"	TEXT NOT NULL,
    "Description"	TEXT NOT NULL,
    "ExternalId"	TEXT NOT NULL UNIQUE,
    "Phone"	TEXT NOT NULL,
    "Source"	INTEGER NOT NULL,
    "UrlResponse"	TEXT NOT NULL,
    "ValidTime"	INTEGER NOT NULL,
    "Password"	TEXT NOT NULL,
    "Username"	TEXT NOT NULL,
    "Pending"	INTEGER NOT NULL DEFAULT 1,
    "Status"	INTEGER NOT NULL DEFAULT 2,
    PRIMARY KEY("Id" AUTOINCREMENT)
   );

  CREATE TABLE "Refund" (
    "Id"	INTEGER NOT NULL,
    "RefundID"	TEXT NOT NULL UNIQUE,
    "Source"	INTEGER NOT NULL,
    "Code"	TEXT,
    "UrlResponse"	TEXT,
    "Bank"	INTEGER,
    "Status"	INTEGER NOT NULL DEFAULT 2,
    "ReferenceRefund"	TEXT,
    "ReferenceRefundTM"	TEXT,
    "ExternalID"	TEXT,
    "BankId"	TEXT,
    "TmId"	TEXT,
    "Msg"	TEXT,
    PRIMARY KEY("Id" AUTOINCREMENT)
   );
```

## Instalación y Ejecución

### Prerrequisitos
- Instala las dependencias del sistema:
  ```bash
  sudo apt update && sudo apt install -y valac meson ninja-build libglib2.0-dev libjson-glib-dev libsoup-3.0-dev libsqlite3-dev dbus
  ```

### Construcción
1. Clona el repositorio:
   ```bash
   git clone https://github.com/rodriguez2508/Virtual-Transfermovil-Test.git
   cd Virtual-Transfermovil-Test
   ```

2. Construye el proyecto:
   ```bash
   meson setup build
   ninja -C build
   ```

3. Crea la base de datos:
   ```bash
   sqlite3 virtualtm.db <<EOF
   CREATE TABLE "Payment" (
     "Id" INTEGER NOT NULL,
     "Amount" REAL NOT NULL,
     "Currency" TEXT NOT NULL,
     "Description" TEXT NOT NULL,
     "ExternalId" TEXT NOT NULL UNIQUE,
     "Phone" TEXT NOT NULL,
     "Source" INTEGER NOT NULL,
     "UrlResponse" TEXT NOT NULL,
     "ValidTime" INTEGER NOT NULL,
     "Password" TEXT NOT NULL,
     "Username" TEXT NOT NULL,
     "Pending" INTEGER NOT NULL DEFAULT 1,
     PRIMARY KEY("Id" AUTOINCREMENT)
   );
   EOF
   ```

### Ejecución
1. Ejecuta el servidor en segundo plano:
   ```bash
   ./build/src/virtualtm-server &
   ```

2. Usa el cliente para listar pagos pendientes:
   ```bash
   ./build/src/virtualtm --list
   ```

3. Para pagar un pago (reemplaza ID con el ExternalId):
   ```bash
   ./build/src/virtualtm --pay ID
   ```

4. Para detener el servidor:
   ```bash
   ./build/src/virtualtm --quit
   ```

## Uso con Docker

### Construcción de la Imagen
```bash
docker build -t virtual-transfermovil-test .
```

### Ejecución
```bash
docker run -p 8999:8999 -v $(pwd)/virtualtm.db:/app/virtualtm.db virtual-transfermovil-test
```

El servidor estará disponible en `http://localhost:8999`.

### Prueba
- Envía una solicitud POST a `http://localhost:8999/` con JSON:
  ```json
  {
    "amount": 100.0,
    "currency": "CUP",
    "description": "Pago de prueba",
    "externalId": "test123",
    "phone": "123456789",
    "source": 1,
    "urlResponse": "http://example.com/callback",
    "validTime": 3600,
    "password": "pass",
    "username": "user"
  }
  ```
- Usa el cliente en otro contenedor o desde el host (con D-Bus configurado).

## Desarrollo con Docker Compose

Para desarrollo, usa `docker-compose.yml` que incluye servicios para servidor y cliente.

### Inicio
```bash
docker-compose up --build virtualtm-server
```

### Prueba con Cliente
```bash
docker-compose --profile client run --rm virtualtm-client
```

Esto lista los pagos pendientes.

### Volúmenes
- La base de datos `virtualtm.db` se persiste en el directorio local.

# Virtual-Transfermovil-Test
