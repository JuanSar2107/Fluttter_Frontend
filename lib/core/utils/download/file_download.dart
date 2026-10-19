/// Descarga de archivos estaticos servidos junto a la app.
///
/// Solo tiene efecto en web: en movil/escritorio la implementacion es un
/// no-op, por eso la importacion es condicional y `package:web` nunca se
/// compila fuera del navegador.
library;

export 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart';
