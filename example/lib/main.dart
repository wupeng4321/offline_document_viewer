import 'package:flutter/material.dart';

import 'design/app_theme.dart';
import 'screens/library_screen.dart';

void main() => runApp(const ExampleApp());

/// Demonstrates `offline_document_viewer` inside a small document library.
///
/// The package itself ships no chrome — this app supplies the shell, the
/// search field, the outline sheet and the error copy, which is exactly the
/// division of labour the package is designed for.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Document Viewer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const LibraryScreen(),
    );
  }
}
