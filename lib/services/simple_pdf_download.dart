// lib/services/simple_pdf_download.dart

// Conditional wrapper to select platform implementation
export 'simple_pdf_download_web.dart' if (dart.library.io) 'simple_pdf_download_io.dart';
