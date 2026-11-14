import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models.dart';
import '../router.dart';

const _teal = Color(0xFF075E54);

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.router});
  final HybridRouter router;
  @override State<ChatPage> createState() => _S();
}

class _S extends State<ChatPage> {
  final _items = <Msg>[]; final _c = TextEditingController(); final _sc = ScrollController();
  final _rec = AudioRecorder();
  bool _recording = false, _typing = false;
  StreamSubscription<Position>? _loc; String _route = '';
  HybridRouter get r => widget.router;

  @override void initState() {
    super.initState();
    _route = r.route;
    r.messages.listen((m) {
      setState(() {
        if (m.kind == Kind.location) _items.removeWhere((x) => x.kind == Kind.location && x.from == m.from);
        _items.add(m);
      });
      Future.delayed(const Duration(milliseconds: 80), () {
        if (_sc.hasClients) _sc.animateTo(_sc.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });
    });
    r.status.listen((s) => setState(() => _route = s));
  }

  bool get _bt => r.route == 'Bluetooth';

  Future<void> _image(ImageSource src) async {
    final f = await ImagePicker().pickImage(source: src, maxWidth: _bt ? 320 : 1280, imageQuality: _bt ? 40 : 80);
    if (f != null) await r.send(Kind.image, base64Encode(await File(f.path).readAsBytes()));
  }

  Future<void> _startRec() async {
    if (!await _rec.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    await _rec.start(RecordConfig(encoder: AudioEncoder.aacLc, bitRate: _bt ? 16000 : 48000, sampleRate: 16000),
        path: '${dir.path}/v${DateTime.now().millisecondsSinceEpoch}.m4a');
    setState(() => _recording = true);
  }

  Future<void> _stopRec() async {
    final p = await _rec.stop(); setState(() => _recording = false);
    if (p != null) await r.send(Kind.audio, base64Encode(await File(p).readAsBytes()));
  }

  Future<void> _toggleLoc() async {
    if (_loc != null) { await _loc!.cancel(); setState(() => _loc = null); return; }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
    setState(() => _loc = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10))
        .listen((x) => r.send(Kind.location, '${x.latitude.toStringAsFixed(5)},${x.longitude.toStringAsFixed(5)}')));
  }

  void _test() => showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('Prueba de conexión'),
    content: Text('Internet: ${r.net.available ? "✅" : "❌"}\nBluetooth (vecinos): ${r.ble.available ? "✅" : "❌"}\nRuta activa: ${r.route}'),
  ));

  void _send() { final t = _c.text.trim(); if (t.isEmpty) return; r.send(Kind.text, t); _c.clear(); setState(() => _typing = false); }

  void _attach() => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(
    margin: const EdgeInsets.all(12), padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF233138) : Colors.white, borderRadius: BorderRadius.circular(26)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, mainAxisSize: MainAxisSize.min, children: [
      _opt(Icons.photo_library, 'Galería', const [Color(0xFFB49BFF), Color(0xFF5B3FD1)], () => _image(ImageSource.gallery)),
      _opt(Icons.photo_camera, 'Cámara', const [Color(0xFFFF8FB3), Color(0xFFD81B60)], () => _image(ImageSource.camera)),
      _opt(_loc != null ? Icons.location_off : Icons.location_on, _loc != null ? 'Detener' : 'Ubicación', const [Color(0xFF3FE0CC), Color(0xFF0C8F83)], _toggleLoc),
    ])));

  Widget _opt(IconData i, String t, List<Color> c, VoidCallback f) => GestureDetector(
    onTap: () { Navigator.pop(context); f(); },
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
        child: Icon(i, color: Colors.white, size: 30)),
      const SizedBox(height: 9), Text(t, style: const TextStyle(fontSize: 13))]));

  Widget _bubble(Msg m) {
    final dark = Theme.of(context).brightness == Brightness.dark, mine = m.from == r.me;
    final bg = mine ? (dark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3)) : (dark ? const Color(0xFF202C33) : Colors.white);
    final time = DateTime.fromMillisecondsSinceEpoch(m.ts); final hm = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final Widget body = switch (m.kind) {
      Kind.text => Text(m.body, style: const TextStyle(fontSize: 15.5)),
      Kind.image => GestureDetector(
          onTap: () => showDialog(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: Image.memory(base64Decode(m.body))))),
          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(base64Decode(m.body), fit: BoxFit.cover))),
      Kind.audio => _AudioBubble(m.body),
      Kind.location => Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on, color: Colors.red), const SizedBox(width: 6),
          Flexible(child: Text('Ubicación en vivo\n${m.body}', style: const TextStyle(fontSize: 14)))]),
    };
    return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8), padding: const EdgeInsets.fromLTRB(9, 6, 9, 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12), topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(mine ? 12 : 2), bottomRight: Radius.circular(mine ? 2 : 12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (!mine) Text(m.from, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.primaries[m.from.hashCode.abs() % Colors.primaries.length])),
          body,
          Align(alignment: Alignment.centerRight, child: Text('$hm${mine ? '  ✓✓' : ''}', style: const TextStyle(fontSize: 10.5, color: Colors.grey))),
        ])));
  }

  @override Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
      appBar: AppBar(backgroundColor: dark ? const Color(0xFF1F2C34) : _teal, foregroundColor: Colors.white,
        title: Row(children: [
          ClipOval(child: Image.asset('assets/icon/icon.png', width: 40, height: 40)), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Malla · Grupo', style: TextStyle(fontSize: 17)),
            Text(_route == 'Sin ruta' ? 'sin conexión' : 'vía $_route', style: const TextStyle(fontSize: 12, color: Colors.white70))]),
        ]),
        actions: [PopupMenuButton<String>(onSelected: (v) {
            if (v == 'test') { _test(); } else { setState(() { r.mode = Mode.values.byName(v); _route = r.route; }); }
          }, itemBuilder: (_) => const [
            PopupMenuItem(value: 'auto', child: Text('Modo: Auto')),
            PopupMenuItem(value: 'internet', child: Text('Modo: Solo Internet')),
            PopupMenuItem(value: 'bluetooth', child: Text('Modo: Solo Bluetooth')),
            PopupMenuItem(value: 'test', child: Text('🧪 Probar conexión'))])]),
      body: Column(children: [
        Expanded(child: ListView(controller: _sc, padding: const EdgeInsets.symmetric(vertical: 8), children: _items.map(_bubble).toList())),
        SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(6, 4, 6, 6), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Container(
            decoration: BoxDecoration(color: dark ? const Color(0xFF202C33) : Colors.white, borderRadius: BorderRadius.circular(26)),
            child: Row(children: [
              IconButton(onPressed: _attach, icon: const Icon(Icons.attach_file, color: Colors.grey)),
              Expanded(child: _recording
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('🔴 Grabando… suelta para enviar'))
                : TextField(controller: _c, minLines: 1, maxLines: 5, onChanged: (v) => setState(() => _typing = v.trim().isNotEmpty),
                    decoration: const InputDecoration(hintText: 'Mensaje', border: InputBorder.none))),
            ]))),
          const SizedBox(width: 6),
          GestureDetector(
            onLongPressStart: _typing ? null : (_) => _startRec(),
            onLongPressEnd: _typing ? null : (_) => _stopRec(),
            onTap: _typing ? _send : null,
            child: CircleAvatar(radius: 24, backgroundColor: _recording ? Colors.red : const Color(0xFF00A884),
              child: Icon(_typing ? Icons.send : Icons.mic, color: Colors.white))),
        ]))),
      ]),
    );
  }
}

class _AudioBubble extends StatefulWidget {
  const _AudioBubble(this.b64);
  final String b64;
  @override State<_AudioBubble> createState() => _AB();
}

class _AB extends State<_AudioBubble> {
  final _p = AudioPlayer(); bool _playing = false; Duration _pos = Duration.zero, _dur = Duration.zero; bool _loaded = false;
  @override void initState() {
    super.initState();
    _p.onPositionChanged.listen((d) => setState(() => _pos = d));
    _p.onDurationChanged.listen((d) => setState(() => _dur = d));
    _p.onPlayerComplete.listen((_) => setState(() { _playing = false; _pos = Duration.zero; }));
  }
  @override void dispose() { _p.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    if (_playing) { await _p.pause(); setState(() => _playing = false); return; }
    if (!_loaded) {
      final f = File('${(await getTemporaryDirectory()).path}/p${widget.b64.hashCode}.m4a');
      await f.writeAsBytes(base64Decode(widget.b64));
      await _p.setSource(DeviceFileSource(f.path)); _loaded = true;
    }
    await _p.resume(); setState(() => _playing = true);
  }

  @override Widget build(BuildContext context) => SizedBox(width: 220, child: Row(children: [
    IconButton(onPressed: _toggle, icon: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 30)),
    Expanded(child: LinearProgressIndicator(value: _dur.inMilliseconds == 0 ? 0 : _pos.inMilliseconds / _dur.inMilliseconds)),
    const SizedBox(width: 6), const Icon(Icons.mic, size: 16, color: Colors.grey),
  ]));
}
