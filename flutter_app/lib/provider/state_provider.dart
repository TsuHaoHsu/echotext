import 'package:flutter_riverpod/flutter_riverpod.dart';

// user login status
final loginStatusProvider = StateProvider((ref) => false);
// user online status
final onlineStatusProvider = StateProvider((ref) => false);