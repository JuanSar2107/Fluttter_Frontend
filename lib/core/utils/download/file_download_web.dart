import 'package:web/web.dart' as web;

/// Crea un `<a download>` temporal y lo pulsa, para que el navegador guarde
/// el archivo en lugar de intentar abrirlo.
void downloadFile(String url, {required String fileName}) {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
