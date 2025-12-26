// Conditional export: picks IO or Web implementation.
export 'secret_store_io.dart' if (dart.library.html) 'secret_store_web.dart';
