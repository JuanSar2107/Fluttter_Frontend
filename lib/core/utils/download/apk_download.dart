import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'file_download.dart';

/// Ruta del APK servido junto a la version web (`web/downloads/`).
const String kAndroidApkPath = 'downloads/aeroparts.apk';

/// Descarga el APK de Android desde la version web.
///
/// En movil/escritorio no hay nada que descargar: se avisa con un SnackBar.
void downloadAndroidApk(BuildContext context) {
  if (kIsWeb) {
    downloadFile(kAndroidApkPath, fileName: 'aeroparts.apk');
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('La descarga del APK está disponible en la versión web.'),
    ),
  );
}
