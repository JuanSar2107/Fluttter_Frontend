import 'dart:convert';

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

/// Descarga [content] generado en memoria como un archivo de texto.
bool downloadText(
  String content, {
  required String fileName,
  String mimeType = 'text/plain',
}) {
  final encoded = base64Encode(utf8.encode(content));
  downloadFile(
    'data:$mimeType;charset=utf-8;base64,$encoded',
    fileName: fileName,
  );
  return true;
}

/// Abre el dialogo de impresion del navegador (permite "Guardar como PDF").
bool printPage() {
  web.window.print();
  return true;
}
