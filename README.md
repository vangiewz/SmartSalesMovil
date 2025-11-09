# SmartSales Móvil

Aplicación móvil Flutter para SmartSales - sistema completo de comercio electrónico con gestión de productos, carrito, pagos, direcciones y garantías.

## 📋 Características

### ✅ Implementadas

- **Autenticación**: Login/Register usando endpoints del backend (`/api/login/`, `/api/register/`)
- **Catálogo de Productos**: 
  - Lista paginada con búsqueda y filtros (marca, tipo)
  - Vista detallada de producto
  - Imágenes con caché
- **Carrito de Compras**:
  - Gestión client-side con persistencia local (SharedPreferences)
  - Agregar/eliminar/actualizar cantidades
  - Persistencia entre sesiones
- **Checkout y Pagos**:
  - Integración con backend Stripe via `/api/pagos/iniciar-checkout/`
  - Obtención de `clientSecret` para confirmar pago
  - Confirmación de pago via `/api/pagos/confirmar-pago/`
  - Historial de pagos con recibos
- **Direcciones**: CRUD completo de direcciones de envío
- **Garantías**:
  - Ver productos elegibles para garantía
  - Crear reclamos de garantía
  - Ver estado de reclamos propios
- **UI/UX**:
  - Tema personalizado con paleta de colores brand
  - Navegación intuitiva
  - Estados de carga y error
  - Auth gate automático

## 🚀 Configuración y Ejecución

### Pre-requisitos

- Flutter SDK 3.9.2+
- Android Studio / Xcode (para emuladores)
- Backend SmartSales corriendo localmente o en producción

### 1. Instalar dependencias

```powershell
flutter pub get
```

### 2. Configurar base URL

Edita `lib/src/api/api_client.dart`:

```dart
const bool USE_PROD = false; // true para producción

const BASE_URLS = {
  'local': 'http://127.0.0.1:8000/api/',
  'prod': 'https://smartsalesbackend.onrender.com/api/',
};
```

**Importante**: Para Android emulator, usa `http://10.0.2.2:8000/api/` en lugar de `127.0.0.1` si el backend corre en tu máquina local.

### 3. Ejecutar la app

```powershell
# Ejecutar en dispositivo/emulador
flutter run

# O específico:
flutter run -d chrome          # Web (desarrollo rápido)
flutter run -d android         # Android
flutter run -d ios             # iOS (macOS solamente)
```

## 🔑 Autenticación

La app **NO requiere .env** ni keys de Supabase en el frontend. Toda la autenticación se maneja via backend:

- **Registro**: `POST /api/register/` (email, password, nombre, telefono)
- **Login**: `POST /api/login/` (email, password)
- **Token**: JWT retornado en `tokens.access` se guarda en secure storage
- **Validación**: Auth gate valida token con `GET /api/me/` al iniciar

## 💳 Pagos (Stripe)

### Flujo implementado

1. Usuario agrega productos al carrito
2. En Checkout, selecciona dirección de envío
3. App llama `POST /api/pagos/iniciar-checkout/` con items y dirección
4. Backend crea PaymentIntent y retorna `clientSecret` y `paymentIntentId`
5. **(Opcional)** Integrar `flutter_stripe` SDK para confirmar pago client-side
6. App llama `POST /api/pagos/confirmar-pago/` para obtener `venta_id` y `receipt_url`

## � Dependencias Principales

```yaml
dio: ^5.1.2                        # HTTP client
flutter_secure_storage: ^8.0.0    # Almacenamiento seguro de tokens
shared_preferences: ^2.2.2        # Persistencia de carrito
cached_network_image: ^3.3.1      # Caché de imágenes
```

**Nota**: No se requiere `supabase_flutter` ni `flutter_dotenv` porque usamos los endpoints del backend directamente.

### Error de red en Android emulator

Si usas `127.0.0.1` y no conecta:
```dart
'local': 'http://10.0.2.2:8000/api/',  // Android emulator
```

### Cleartext traffic no permitido (Android 9+)

Agrega en `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

## 🎨 Paleta de Colores

```dart
brandPrimary: #B832FA
brandAccent: #FF4DD2
bgBase: #FFF7FF
success: #24C38B
warning: #F6C445
danger: #FF4E6E
```

## 📱 Plataformas Soportadas

- ✅ Android
- ✅ iOS
- ✅ Web (desarrollo/testing)

---

**Desarrollado con ❤️ usando Flutter**
