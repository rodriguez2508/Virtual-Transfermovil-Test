# VirtualTM API Documentation

VirtualTM es un emulador de la API REST de Transfermovil para Cuba. Esta documentación describe los endpoints implementados basados en la API oficial.

## Autenticación

Todos los requests requieren headers de autenticación:

- `username`: Nombre de usuario
- `source`: Identificador de entidad (integer)
- `password`: Contraseña generada con SHA512

### Generación de Password

```
password = SHA512(username + día + mes + año + semilla + source) → Base64 (usando digest binario)
```

- Día, mes, año sin ceros iniciales (ej: 16 de diciembre 2025 = 16122025)
- Semilla configurable en el servidor (default "test")
- Para testing, acepta `password: "test"`

## Endpoints

### 1. Crear Orden de Pago

**URL:** `POST /RestExternalPayment.svc/payOrder`

**Headers:**
```
username: <string>
source: <integer>
password: <string>
Content-Type: application/json
```

**Request Body:**
```json
{
  "request": {
    "Amount": 1.0,
    "Currency": "CUP",
    "Description": "Descripción del pago",
    "ExternalId": "123456",
    "Phone": "5352880000",
    "Source": 12,
    "UrlResponse": "http://example.com/notification",
    "ValidTime": 3600
  }
}
```

**Response:**
```json
{
  "PayOrderResult": {
    "Resultmsg": "Ok",
    "Success": true,
    "OrderId": "1"
  }
}
```

**Parámetros:**
- `Amount`: Importe (decimal)
- `Currency`: Moneda (CUP/CUC)
- `Description`: Descripción (máx 200 chars)
- `ExternalId`: ID externo único (máx 12 chars, recomendado <2 no numéricos)
- `Phone`: Número de celular (10 dígitos)
- `Source`: Identificador de entidad
- `UrlResponse`: URL para notificaciones
- `ValidTime`: Segundos de validez (0 = ilimitado)

### 2. Consultar Estado de Pago

**URL:** `GET /RestExternalPayment.svc/getStatusOrder/{ExternalId}/{Source}`

**Headers:**
```
username: <string>
source: <integer>
password: <string>
```

**Response:**
```json
{
  "GetStatusOrderResult": {
    "Resultmsg": "Ok",
    "Success": true,
    "Bank": 1,
    "BankId": 1234,
    "ExternalId": "123456",
     "OrderId": "1",
    "Status": 3,
    "TmId": 5678
  }
}
```

**Estados:**
- 2: Operación en proceso
- 3: Operación exitosa pendiente notificar al tercero
- 4: Operación exitosa notificada al tercero
- 5: Operación fallida notificada al tercero
- 6: Operación fallida
- 7: Operación pendiente de rollback
- 8: Operación con rollback exitoso
- 9: Expirada por tiempo sin solicitud del cliente

### 3. Crear Orden de Devolución

**URL:** `POST /RestExternalPayment.svc/refundPay`

**Headers:**
```
username: <string>
source: <integer>
password: <string>
Content-Type: application/json
```

**Request Body:**
```json
{
  "request": {
    "RefundID": "refund123",
    "Source": 12,
    "Code": "encrypted_data",
    "UrlResponse": "http://example.com/notification",
    "Bank": 1
  }
}
```

**Response:**
```json
{
  "RefundPayResult": {
    "RefundID_Order": "refund123",
    "Resultmsg": "Ok",
    "Success": true
  }
}
```

**Parámetros:**
- `RefundID`: ID de devolución (máx 20 chars)
- `Source`: Identificador de entidad
- `Code`: Datos encriptados (máx 512 chars)
- `UrlResponse`: URL para notificaciones
- `Bank`: Número de banco

### 4. Consultar Estado de Devolución

**URL:** `GET /RestExternalPayment.svc/getStatusRefundOrder/{RefundID}/{Source}`

**Headers:**
```
username: <string>
source: <integer>
password: <string>
```

**Response:**
```json
{
  "getStatusRefundOrderResult": {
    "RefundID": "refund123",
    "ReferenceRefund": "BANK123",
    "ReferenceRefundTM": "TM456",
    "Status": 3,
    "ExternalID": "123456",
    "BankId": "BANK789",
    "TmId": "TM101",
    "Msg": "Mensaje de estado",
    "Resultmsg": "Ok",
    "Success": true
  }
}
```

## Notificaciones

### Notificación de Pago

**Método:** POST a `UrlResponse` especificado en payOrder

**Request Body:**
```json
{
  "Source": 12,
  "BankId": 1234,
  "TmId": 5678,
  "Phone": "5352880000",
  "Msg": "Pago exitoso",
  "ExternalId": "123456",
  "Status": 3,
  "Bank": 1
}
```

**Response Esperado:**
```json
{
  "Success": true,
  "Resultmsg": "Ok",
  "Status": 1
}
```

### Notificación de Devolución

**Método:** POST a `UrlResponse` especificado en refundPay

**Request Body:**
```json
{
  "RefundID": "refund123",
  "ReferenceRefund": "BANK123",
  "ReferenceRefundTM": "TM456",
  "Status": 3,
  "ExternalID": "123456",
  "BankId": "BANK789",
  "TmId": "TM101",
  "Msg": "Devolución procesada",
  "Success": true,
  "Resultmsg": "Ok"
}
```

**Response Esperado:**
```json
{
  "Success": true,
  "Resultmsg": "Ok",
  "Status": 1
}
```

## Códigos de Error

- **400 Bad Request**: Headers faltantes, auth inválida, parámetros incorrectos
- **404 Not Found**: Endpoint no encontrado, pago/devolución no existe
- **500 Internal Server Error**: Error interno del servidor

## Configuración del Servidor

- **Puerto:** `--port` (default 8999)
- **Base de datos:** `--database` (default virtualtm.db)
   - **Semilla auth:** `--seed` (default "test")
- **Endpoint base:** `--endpoint` (default "/RestExternalPayment.svc")

## Ejemplos de Uso

### Crear Pago
```bash
curl -X POST -H "username:user" -H "password:test" -H "source:12" \
  -H "Content-Type:application/json" \
  -d '{"request":{"Amount":1,"Currency":"CUP","Description":"test","ExternalId":"123","Phone":"5352880000","Source":12,"UrlResponse":"http://example.com","ValidTime":0}}' \
  http://localhost:8999/RestExternalPayment.svc/payOrder
```

### Consultar Estado
```bash
curl -X GET -H "username:user" -H "password:test" -H "source:12" \
  http://localhost:8999/RestExternalPayment.svc/getStatusOrder/123/12
```

## Notas

- Para testing, el servidor acepta `password: test` como válido.
- La base de datos debe crearse manualmente con el SQL en README.md.
- Estados se actualizan automáticamente en notificaciones exitosas.</content>
<parameter name="filePath">api.md