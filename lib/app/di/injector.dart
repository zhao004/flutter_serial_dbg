import 'package:get_it/get_it.dart';

import 'register_core.dart';
import 'register_pages.dart';
import 'register_transport.dart';

final GetIt getIt = GetIt.instance;

class Injector {
  Injector._();

  static void registerAll() {
    registerCore();
    registerTransport();
    registerPages();
  }
}
