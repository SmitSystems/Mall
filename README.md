# Malla — chat estilo WhatsApp con Internet + malla Bluetooth

## Archivos (todo debe quedar en la RAÍZ del repositorio)
```
index.html            prototipo web (GitHub Pages)
manifest.webmanifest  datos de instalación (nombre, colores, iconos)
sw.js                 service worker: instalable y abre sin Internet
icons/                icon-192, icon-512, icon-maskable-512, apple-touch-icon, favicon
.nojekyll  .gitignore (archivos que empiezan con punto)
server/               servidor WebSocket (Node)
app/                  app Flutter
  assets/icon/        icon.png, icon_ios.png, foreground.png, background.png
  web/                index.html, manifest e iconos de Flutter web
.github/workflows/    compila el APK en cada push
```
Si al subir por la web de GitHub los archivos con punto quedaron como `_gitignore` / `_nojekyll`, renómbralos a `.gitignore` / `.nojekyll`.
La carpeta `icons/` es obligatoria: sin ella no hay icono al instalar.

## Instalar la web como app con su icono
- Publica: Settings → Pages → Branch main, carpeta /(root).
- Android (Chrome): menú de tres puntos de la app → «Instalar app», o menú de Chrome → «Instalar aplicación». Usa icon-192/512 y el maskable.
- iPhone (Safari): Compartir → «Añadir a pantalla de inicio». Usa apple-touch-icon.png.
- Al reinstalar, borra la anterior: el sistema guarda el icono viejo.

## Icono en la app Flutter (APK / iOS)
`cd app && flutter create . && flutter pub get && dart run flutter_launcher_icons`
Genera los iconos de lanzador de Android (con versión adaptable) e iOS desde assets/icon/. El flujo de GitHub ya lo ejecuta.

## Arranque de la app
1. `cd server && npm i && node server.js`
2. `cd app && flutter create . && bash tool/setup_android.sh && flutter pub get && dart run flutter_launcher_icons`
3. `flutter run --dart-define=WS_URL=ws://TU_IP:8080`

## Estado honesto
- index.html es un prototipo con «vecino» simulado; no conecta a otras personas.
- La app Flutter no fue compilada ni probada. `lib/transports/ble_radio.dart` es un stub (sin Bluetooth real).
- Sin cifrado, cuentas ni salas privadas.
