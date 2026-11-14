# Malla — chat estilo WhatsApp con Internet + malla Bluetooth

## Qué hay en cada carpeta
```
index.html              ← prototipo web (abre directo o publícalo con GitHub Pages)
manifest.webmanifest    ← instalable como app web (PWA)
icons/                  ← favicon, apple-touch, 192, 512, maskable
server/                 ← servidor WebSocket (Node)
app/                    ← app Flutter (Android/iOS/Web)
  lib/                  ← código Dart
  web/                  ← index.html, manifest e iconos de Flutter web
  assets/icon/icon.png  ← icono 1024 para Android/iOS
  tool/setup_android.sh ← permisos Android
.github/workflows/      ← compila el APK en cada push
```
## Ver el index.html en GitHub
Settings → Pages → Branch: main, carpeta /(root) → tu sitio queda en https://USUARIO.github.io/REPO/

## Iconos
- Web/PWA: ya incluidos (icons/ y app/web/icons/).
- Android/iOS: `cd app && flutter create . && dart run flutter_launcher_icons` los genera desde assets/icon/icon.png.
  (Las carpetas android/ e ios/ no vienen en el pack: las crea `flutter create .`.)

## Arranque de la app
1. `cd server && npm i && node server.js`
2. `cd app && flutter create . && bash tool/setup_android.sh && flutter pub get && dart run flutter_launcher_icons`
3. `flutter run --dart-define=WS_URL=ws://TU_IP:8080`

## Estado honesto
- index.html es un prototipo con «vecino» simulado; no conecta a otras personas.
- La app Flutter no fue compilada ni probada por mí. `lib/transports/ble_radio.dart` es un stub (sin Bluetooth real).
- Sin cifrado, cuentas ni salas privadas.
