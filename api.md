# VirtualTM API Documentation

**IMPORTANTE: Esta NO es la documentación oficial de la API de Transfermovil. Es una documentación del emulador VirtualTM, que simula la API externa de pagos de Transfermovil para fines de desarrollo y testing. Para la documentación oficial, consulta los recursos proporcionados por ETECSA o Transfermovil.**

VirtualTM es un emulador de la API REST (y próximamente SOAP) de Transfermovil para Cuba. Esta documentación describe los endpoints implementados basados en la API oficial de servicios externos de pago.

## Autenticación

Todos los requests requieren headers de autenticación:

- `username`: Nombre de usuario
- `source`: Identificador de entidad (integer)
- `password`: Contraseña generada con SHA512

### Generación de Password

```
password = SHA512(username + día + mes + año + semilla + source) → Base64 (usando digest binario)
```

- Día, mes, año sin ceros iniciales (ej: 17 de diciembre 2025 = 17122025)
- Semilla configurable en el servidor (default "test")
- Nota: El servidor valida la contraseña generada dinámicamente; no acepta contraseñas fijas como "test" a menos que se configure explícitamente.

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

**Status Codes:**
- `200 OK`: Operación exitosa
- `400 Bad Request`: Error en autenticación o parámetros

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

**Status Codes:**
- `200 OK`: Orden encontrada
- `404 Not Found`: Orden no encontrada
- `400 Bad Request`: Error en autenticación

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

## Endpoints SOAP (Próximamente)

VirtualTM actualmente implementa solo REST, pero la API oficial incluye soporte SOAP. Aquí se documentan para referencia futura.

### 1. Crear Orden de Pago (SOAP)

**URL:** `POST https://SERVIDOR:PUERTO/ExternalPaymentServices.svc?wsdl` (Operación: PayOrder)

**Headers:**
```
username: <string>
source: <integer>
password: <string>
Content-Type: text/xml
```

**Request Body (XML):**
```xml
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:ext="http://schemas.datacontract.org/2004/07/ExternalPayment.DataContracts.Requests">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:PayOrder>
         <tem:request>
            <ext:Amount>1</ext:Amount>
            <ext:Currency>CUP</ext:Currency>
            <ext:Description>test</ext:Description>
            <ext:ExternalId>1478</ext:ExternalId>
            <ext:Phone>5352880000</ext:Phone>
            <ext:Source>12</ext:Source>
            <ext:UrlResponse>http://localhost</ext:UrlResponse>
            <ext:ValidTime>0</ext:ValidTime>
         </tem:request>
      </tem:PayOrder>
   </soapenv:Body>
</soapenv:Envelope>
```

**Response (XML):**
```xml
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
   <s:Body>
      <PayOrderResponse xmlns="http://tempuri.org/">
         <PayOrderResult xmlns:a="http://schemas.datacontract.org/2004/07/ExternalPayment.DataContracts.Responses" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
            <a:Resultmsg>Mensaje</a:Resultmsg>
            <a:Success>true</a:Success>
            <a:OrderId>1234</a:OrderId>
         </PayOrderResult>
      </PayOrderResponse>
   </s:Body>
</s:Envelope>
```

### 2. Consultar Estado de Pago (SOAP)

**URL:** `POST https://SERVIDOR:PUERTO/ExternalPaymentServices.svc?wsdl` (Operación: GetStatusOrder)

**Request Body (XML):**
```xml
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:ext="http://schemas.datacontract.org/2004/07/ExternalPayment.DataContracts.Requests">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:GetStatusOrder>
         <tem:request>
            <ext:ExternalId>1478</ext:ExternalId>
            <ext:Source>12</ext:Source>
         </tem:request>
      </tem:GetStatusOrder>
   </soapenv:Body>
</soapenv:Envelope>
```

**Response (XML):**
```xml
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
   <s:Body>
      <GetStatusOrderResponse xmlns="http://tempuri.org/">
         <GetStatusOrderResult xmlns:a="http://schemas.datacontract.org/2004/07/ExternalPayment.DataContracts.Responses" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
            <a:Resultmsg>mensaje</a:Resultmsg>
            <a:Success>true/false</a:Success>
            <a:BankId>Id Banco</a:BankId>
            <a:ExternalId>Id de Transaccion del comercio</a:ExternalId>
            <a:OrderId>Id de Orden de pago</a:OrderId>
            <a:Status>Estado</a:Status>
            <a:TmId>Id de Transaccion de Transfermovil</a:TmId>
            <a:Bank>No. de banco</a:Bank>
         </GetStatusOrderResult>
      </GetStatusOrderResponse>
   </s:Body>
</s:Envelope>
```

### 3. Crear Orden de Devolución (SOAP)

**URL:** `POST https://SERVIDOR:PUERTO/ExternalPaymentServices.svc?wsdl` (Operación: RefundPay)

**Request Body (XML):**
```xml
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:ext="http://schemas.datacontract.org/2004/07/ExternalPayment.DataContracts.Requests">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:RefundPay>
         <tem:request>
            <ext:Bank>1</ext:Bank>
            <ext:Code>dsf</ext:Code>
            <ext:RefundID>23423444</ext:RefundID>
            <ext:Source>1</ext:Source>
            <ext:UrlResponse>as</ext:UrlResponse>
         </tem:request>
      </tem:RefundPay>
   </soapenv:Body>
</soapenv:Envelope>
```

**Response (XML):**
```xml
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
   <s:Body>
      <RefundPayResponse xmlns="http://tempuri.org/">
         <RefundPayResult xmlns:a="http://schemas.datacontract.org/2004/07/ExternalPayment.DataContracts.Responses" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
            <a:Resultmsg>Orden insertada</a:Resultmsg>
            <a:Success>true</a:Success>
            <a:RefundID_Order>19</a:RefundID_Order>
         </RefundPayResult>
      </RefundPayResponse>
   </s:Body>
</s:Envelope>
```

### 4. Consultar Estado de Devolución (SOAP)

**URL:** `POST https://SERVIDOR:PUERTO/ExternalPaymentServices.svc?wsdl` (Operación: getStatusRefundOrder)

**Request Body (XML):**
```xml
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:ext="http://schemas.datacontract.org/2004/07/ExternalPayment.DataContracts.Requests">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:getStatusRefundOrder>
         <tem:request>
            <ext:RefundID>123</ext:RefundID>
            <ext:Source>1</ext:Source>
         </tem:request>
      </tem:getStatusRefundOrder>
   </soapenv:Body>
</soapenv:Envelope>
```

**Response (XML):**
```xml
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
   <s:Body>
      <getStatusRefundOrderResponse xmlns="http://tempuri.org/">
         <getStatusRefundOrderResult xmlns:a="http://schemas.datacontract.org/2004/07/ExternalPayment.DataContracts.Responses" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
            <a:Success>true</a:Success>
            <a:BankId>1</a:BankId>
            <a:ExternalId>123</a:ExternalId>
            <a:ReferenceRefund>BANK123</a:ReferenceRefund>
            <a:Status>1</a:Status>
            <a:TmId>1234</a:TmId>
            <a:Resultmsg>test api</a:Resultmsg>
         </getStatusRefundOrderResult>
      </getStatusRefundOrderResponse>
   </s:Body>
</s:Envelope>
```

## Integración Móvil y Web

### Estructura de QR

Para generar un código QR que la app de Transfermovil pueda leer, usa la siguiente estructura JSON:

```json
{
  "id_transaccion": "nro_operacion",
  "importe": 1.0,
  "moneda": "CUP",
  "numero_proveedor": 10,
  "version": ""
}
```

- `id_transaccion`: ID de transacción externa (debe coincidir con el ExternalId usado en payOrder, máx 2 caracteres no numéricos + 10 numéricos).
- `importe`: Monto decimal.
- `moneda`: "CUP" o "CUC".
- `numero_proveedor`: Identificador del proveedor.
- `version`: Campo opcional.

### Mecanismo de Intents (Android)

Para enviar parámetros desde una app de tercero a Transfermovil vía Intent:

```java
Intent sendIntent = new Intent();
sendIntent.setPackage("cu.etecsa.cubacel.tr.tm");
sendIntent.setAction(Intent.ACTION_SEND);
sendIntent.putExtra(Intent.EXTRA_TEXT, jsonParametros);
sendIntent.setType("text/plain");
startActivity(sendIntent);
```

- `jsonParametros`: JSON idéntico al usado para el QR (ver arriba).
- Paquete: `cu.etecsa.cubacel.tr.tm`.

### Enlaces para Levantar App desde Web

Para abrir Transfermovil desde un navegador web o enlace:

```html
<a href="transfermovil://tm_compra_en_linea/action?id_transaccion=$ID_Trans&importe=$Imp&moneda=CUP&numero_proveedor=$cod">Abrir app de pago</a>
```

- Reemplaza `$ID_Trans`, `$Imp`, `$cod` con los valores reales.
- `id_transaccion`: ID de transacción.
- `importe`: Monto.
- `moneda`: "CUP".
- `numero_proveedor`: Código del proveedor.

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

### Errores Comunes
- **Not authorized, User not present**: Acceso desde IP no autorizada para el usuario.
- **Not authorized, username or password incorrect**: Contraseña o usuario/source incorrectos.
- **La orden ya existe**: ID de orden ya registrado con el mismo source y username (no es error fatal, solo informativo).

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

- La base de datos debe crearse manualmente con el SQL en README.md.
- Estados se actualizan automáticamente en notificaciones exitosas.
- Para notificaciones, usa URLs accesibles vía VPN (no dominios públicos, ya que los VPN no tienen DNS; usa IPs directas).
- VirtualTM no maneja dinero real; es solo para emulación y testing.</content>
<parameter name="filePath">api.md