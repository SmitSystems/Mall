import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models.dart';
import 'transport.dart';

class InternetTransport implements Transport {
  InternetTransport(this.url);
  final String url;
  WebSocketChannel? _ch;
  final _in = StreamController<Msg>.broadcast();
  final _av = StreamController<bool>.broadcast();
  bool _up = false;
  @override String get name => 'Internet';
  @override bool get available => _up;
  @override Stream<Msg> get incoming => _in.stream;
  @override Stream<bool> get availability => _av.stream;
  @override Future<void> start() async => _connect();

  void _set(bool v) { if (_up != v) { _up = v; _av.add(v); } }
  Future<void> _connect() async {
    try {
      _ch = WebSocketChannel.connect(Uri.parse(url));
      await _ch!.ready;
      _set(true);
      _ch!.stream.listen((d) {
        try { _in.add(Msg.fromJson(jsonDecode(d as String))); } catch (_) {}
      }, onDone: _retry, onError: (_) => _retry());
    } catch (_) { _retry(); }
  }
  void _retry() { _set(false); Future.delayed(const Duration(seconds: 3), _connect); }

  @override Future<void> send(Msg m) async {
    if (!_up) throw StateError('sin Internet');
    _ch!.sink.add(jsonEncode(m.toJson()));
  }
}
