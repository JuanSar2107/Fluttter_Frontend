import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'file_download.dart';

/// Instaladores de la app servidos junto a la version web (`web/downloads/`).
enum AppDownload {
  android(
    label: 'Android (APK)',
    path: 'downloads/aeroparts.apk',
    icon: Icons.android,
  ),
  linux(
    label: 'Linux',
    path: 'downloads/aeroparts-linux-x64.tar.gz',
    icon: Icons.terminal,
  ),
  windows(
    label: 'Windows',
    path: 'downloads/aeroparts-windows-x64.zip',
    icon: Icons.window,
  );

  const AppDownload({
    required this.label,
    required this.path,
    required this.icon,
  });

  final String label;
  final String path;
  final IconData icon;

  String get fileName => path.split('/').last;
}

/// Descarga el instalador [target] desde la version web.
///
/// Antes comprueba que el archivo exista en el servidor: asi un paquete que
/// aun no se ha publicado muestra un aviso en lugar de descargar un 404.
Future<void> downloadApp(BuildContext context, AppDownload target) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!kIsWeb) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Las descargas están disponibles en la versión web.'),
      ),
    );
    return;
  }
  if (!await fileExists(target.path)) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'La versión para ${target.label} aún no está disponible.',
        ),
      ),
    );
    return;
  }
  downloadFile(target.path, fileName: target.fileName);
}

/// Botones de descarga de la app (Android, Linux y Windows).
class AppDownloadButtons extends StatelessWidget {
  const AppDownloadButtons({
    super.key,
    this.compact = false,
    this.background = const Color(0xFF2E2821),
    this.border = const Color(0xFF9A9892),
    this.foreground = const Color(0xFFD8C9AE),
  });

  /// Solo icono y nombre corto, para pantallas estrechas.
  final bool compact;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final target in AppDownload.values)
        Tooltip(
          message: 'Descargar app para ${target.label}',
          child: OutlinedButton.icon(
            onPressed: () => downloadApp(context, target),
            style: OutlinedButton.styleFrom(
              backgroundColor: background,
              foregroundColor: foreground,
              side: BorderSide(color: border),
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            icon: Icon(target.icon, size: 16),
            label: Text(
              compact || target != AppDownload.android
                  ? target.label.split(' ').first
                  : 'Descargar App ${target.label}',
            ),
          ),
        ),
    ],
  );
}
