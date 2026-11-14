# Malla — chat estilo WhatsApp con Internet + malla Bluetooth

## Qué incluye
- Chat en tiempo real: texto, imágenes (galería/cámara), notas de voz (mantén el micrófono), ubicación en vivo.
- Burbujas, hora, doble check, fondo y modo oscuro estilo WhatsApp.
- Router híbrido: Internet → Bluetooth (Auto), dedupe, TTL, puente BLE↔Internet, cola offline.
- Servidor WebSocket con historial de los últimos 50 mensajes (sin ubicación).
- Imágenes y audios se comprimen más cuando la ruta es Bluetooth.

## Estado honesto
- No compilado ni probado aquí: revisa versiones al hacer `flutter pub get`.
- `lib/transports/ble_radio.dart` es un STUB: aún no hay radio Bluetooth real (implementar con `bluetooth_low_energy`).
- Sin cifrado, cuentas, sala privada ni persistencia local. Una sola sala pública: no publicar así.

## Arranque
1. `cd server && npm i && node server.js` (despliega en Render/Fly/VPS para uso real)
2. `cd app && flutter create . && bash tool/setup_android.sh && flutter pub get`
3. `flutter run --dart-define=WS_URL=ws://TU_IP:8080`
iOS: añade en Info.plist NSMicrophoneUsageDescription, NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSLocationWhenInUseUsageDescription, NSBluetoothAlwaysUsageDescription.

## GitHub
`.github/workflows/build-apk.yml` compila el APK en cada push a `main`. Crea el secreto `WS_URL` (wss://tu-servidor) en Settings → Secrets → Actions.
