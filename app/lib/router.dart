import 'dart:async';
import 'dart:math';
import 'models.dart';
import 'transports/transport.dart';

enum Mode { auto, internet, bluetooth }

/// Elige ruta, evita duplicados, reenvía por la malla (TTL), hace de puente BLE↔Internet y guarda cola offline.
class HybridRouter {
  HybridRouter(this.net, this.ble, {required this.me});
  final Transport net, ble; final String me;
  Mode mode = Mode.auto;
  final _seen = <String>{}; final _outbox = <Msg>[];
  final _ui = StreamController<Msg>.broadcast();
  final _status = StreamController<String>.broadcast();
  Stream<Msg> get messages => _ui.stream;
  Stream<String> get status => _status.stream;

  String get route {
    final n = net.available, b = ble.available;
    switch (mode) {
      case Mode.internet: return n ? 'Internet' : 'Sin ruta';
      case Mode.bluetooth: return b ? 'Bluetooth' : 'Sin ruta';
      case Mode.auto: return n ? 'Internet' : (b ? 'Bluetooth' : 'Sin ruta');
    }
  }

  Future<void> start() async {
    await Future.wait([net.start(), ble.start()]);
    net.incoming.listen((m) => _recv(m, viaBle: false));
    ble.incoming.listen((m) => _recv(m, viaBle: true));
    net.availability.listen((_) { _flush(); _status.add(route); });
    ble.availability.listen((_) { _flush(); _status.add(route); });
  }

  static String newId() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  Future<void> send(Kind k, String body) async {
    final m = Msg(id: newId(), from: me, kind: k, body: body);
    _seen.add(m.id); _ui.add(m);
    await _dispatch(m);
  }

  Future<void> _dispatch(Msg m) async {
    final r = route;
    try {
      if (r == 'Internet') { await net.send(m); }
      if (mode != Mode.internet && ble.available) { await ble.send(m); } // también a vecinos
      if (r == 'Sin ruta' && !ble.available) _outbox.add(m);
    } catch (_) { _outbox.add(m); }
  }

  Future<void> _flush() async {
    final pending = List<Msg>.from(_outbox); _outbox.clear();
    for (final m in pending) { await _dispatch(m); }
  }

  void _recv(Msg m, {required bool viaBle}) {
    if (!_seen.add(m.id)) return;           // dedupe
    if (_seen.length > 5000) _seen.clear();
    _ui.add(m);
    if (viaBle) {
      if (net.available) net.send(m).catchError((_) {});   // puente a Internet
      if (m.ttl > 0 && ble.available) ble.send(m.hop());   // salto en la malla
    }
  }
}
