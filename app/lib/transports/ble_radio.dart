import 'dart:async';
/// Capa de radio BLE. Implementar con `bluetooth_low_energy`:
///  - Peripheral: publicar servicio kMallaService y una característica con write+notify.
///  - Central: escanear kMallaService, conectar, suscribirse a notify y escribir tramas.
const kMallaService = '6e6d616c-6c61-4d65-7368-000000000001';

abstract class BleRadio {
  Stream<List<int>> get frames;   // tramas recibidas de cualquier vecino
  int get peers;                  // vecinos conectados
  Stream<int> get peerCount;
  Future<void> start();
  Future<void> broadcast(List<int> frame);
}

/// Stub: compila y no hace nada. Sustituir por la implementación real.
class StubBleRadio implements BleRadio {
  @override Stream<List<int>> get frames => const Stream.empty();
  @override int get peers => 0;
  @override Stream<int> get peerCount => const Stream.empty();
  @override Future<void> start() async {}
  @override Future<void> broadcast(List<int> frame) async {}
}
