void downloadFile(String url, {required String fileName}) {}

/// Sin navegador no hay descarga: devuelve `false` para que la UI ofrezca
/// otra alternativa (por ejemplo, copiar al portapapeles).
bool downloadText(
  String content, {
  required String fileName,
  String mimeType = 'text/plain',
}) => false;

/// Sin navegador no hay dialogo de impresion.
bool printPage() => false;

/// Fuera del navegador no hay servidor web que consultar.
Future<bool> fileExists(String url) async => false;
