import 'package:flutter/material.dart';
import 'router.dart';
import 'transports/ble_mesh_transport.dart';
import 'transports/ble_radio.dart';
import 'transports/internet_transport.dart';
import 'ui/chat_page.dart';

const wsUrl = String.fromEnvironment('WS_URL', defaultValue: 'ws://10.0.2.2:8080');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final me = 'user-${DateTime.now().millisecondsSinceEpoch % 100000}';
  final router = HybridRouter(InternetTransport(wsUrl), BleMeshTransport(StubBleRadio()), me: me);
  await router.start();
  runApp(MaterialApp(
    title: 'Malla', theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
    darkTheme: ThemeData(colorSchemeSeed: Colors.blue, brightness: Brightness.dark, useMaterial3: true),
    home: ChatPage(router: router),
  ));
}
