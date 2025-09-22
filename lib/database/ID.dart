import 'package:uuid/uuid.dart';

class ID {
  static String generate() {
    return Uuid().v1();
  }
}