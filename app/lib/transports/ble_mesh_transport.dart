import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import '../models.dart';
import 'ble_radio.dart';
import 'transport.dart';

/// Trama: [tag 4B][idx 2B][total 2B][payload]. Fragmenta mensajes grandes (imágenes) y los reensambla.
class BleMeshTransport implements Transport {
  BleMeshTransport(this.radio, {this.chunk = 180});
  final BleRadio radio; final int chunk;
  final _in = StreamController<Msg>.broadcast();
  final _av = StreamController<bool>.broadcast();
  final _partial = <int, List<List<int>?>>{};
  @override String get name => 'Bluetooth';
  @override bool get available => radio.peers > 0;
  @override Stream<Msg> get incoming => _in.stream;
  @override Stream<bool> get availability => radio.peerCount.map((n) => n > 0);

  @override Future<void> start() async {
    await radio.start();
    radio.frames.listen(_onFrame);
  }

  @override Future<void> send(Msg m) async {
    final data = m.encode(); final tag = Random().nextInt(1 << 31);
    final total = max(1, (data.length / chunk).ceil());
    for (var i = 0; i < total; i++) {
      final part = data.sublist(i * chunk, min(data.length, (i + 1) * chunk));
      final b = BytesBuilder()
        ..add([tag >> 24 & 255, tag >> 16 & 255, tag >> 8 & 255, tag & 255, i >> 8 & 255, i & 255, total >> 8 & 255, total & 255])
        ..add(part);
      await radio.broadcast(b.toBytes());
    }
  }

  void _onFrame(List<int> f) {
    if (f.length < 8) return;
    final tag = (f[0] << 24) | (f[1] << 16) | (f[2] << 8) | f[3];
    final idx = (f[4] << 8) | f[5], total = (f[6] << 8) | f[7];
    final parts = _partial.putIfAbsent(tag, () => List.filled(total, null));
    if (idx >= parts.length) return;
    parts[idx] = f.sublist(8);
    if (parts.every((p) => p != null)) {
      _partial.remove(tag);
      try { _in.add(Msg.decode(parts.expand((p) => p!).toList())); } catch (_) {}
    }
  }
}
