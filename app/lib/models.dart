import 'dart:convert';
enum Kind { text, image, location, audio }

class Msg {
  final String id, from, body; final Kind kind; final int ts, ttl;
  Msg({required this.id, required this.from, required this.kind, required this.body, int? ts, this.ttl = 5})
      : ts = ts ?? DateTime.now().millisecondsSinceEpoch;
  Msg hop() => Msg(id: id, from: from, kind: kind, body: body, ts: ts, ttl: ttl - 1);
  Map<String, dynamic> toJson() => {'id': id, 'from': from, 'k': kind.index, 'b': body, 't': ts, 'ttl': ttl};
  factory Msg.fromJson(Map<String, dynamic> j) => Msg(id: j['id'], from: j['from'], kind: Kind.values[j['k']], body: j['b'], ts: j['t'], ttl: j['ttl']);
  List<int> encode() => utf8.encode(jsonEncode(toJson()));
  static Msg decode(List<int> b) => Msg.fromJson(jsonDecode(utf8.decode(b)));
}
