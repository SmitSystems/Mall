import '../models.dart';
abstract class Transport {
  String get name;
  bool get available;
  Stream<Msg> get incoming;
  Stream<bool> get availability;
  Future<void> start();
  Future<void> send(Msg m);
}
