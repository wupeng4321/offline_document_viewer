import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:offline_document_viewer/offline_document_viewer.dart';

import '../design/app_theme.dart';
import '../design/component.dart';
import '../design/paper_backdrop.dart';
import '../design/pressable.dart';
import '../widgets/format_badge.dart';
import 'viewer_screen.dart';

/// A document held by the example app.
class LibraryItem {
  const LibraryItem({
    required this.name,
    required this.bytes,
    required this.format,
  });

  final String name;
  final Uint8List bytes;
  final DocumentFormat format;

  String get baseName {
    final int dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }

  String get extension {
    final int dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toUpperCase();
  }
}

/// Lists documents and opens them.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  /// One file per supported format, so the demo exercises every engine path.
  static const List<String> _samples = <String>[
    'assets/samples/sample.pdf',
    'assets/samples/sample.docx',
    'assets/samples/sample.xlsx',
    'assets/samples/edge-cases.pptx',
    'assets/samples/sample.rtf',
    'assets/samples/sample.doc',
    'assets/samples/sample.xls',
    'assets/samples/sample.ppt',
    'assets/samples/sample.csv',
  ];

  final List<LibraryItem> _items = <LibraryItem>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSamples();
  }

  Future<void> _loadSamples() async {
    for (final String path in _samples) {
      final ByteData data = await rootBundle.load(path);
      final Uint8List bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final String name = path.split('/').last;

      // Validating before adding keeps broken files out of the list — the
      // same check the viewer would run, just earlier.
      final Object report =
          DocumentPreflight.inspect(bytes: bytes, fileName: name);
      if (report is PreflightReport && mounted) {
        setState(() {
          _items.add(
            LibraryItem(name: name, bytes: bytes, format: report.format),
          );
        });
      }
    }
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final List<PlatformFile> picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: DocumentFormat.values
            .expand((DocumentFormat f) => f.extensions)
            .toSet()
            .toList(),
      );
      final PlatformFile? file = picked.firstOrNull;
      if (file == null) {
        return;
      }
      final Uint8List bytes = await file.readAsBytes();

      final Object report =
          DocumentPreflight.inspect(bytes: bytes, fileName: file.name);
      if (!mounted) {
        return;
      }
      if (report is DocumentFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_describe(report))),
        );
        return;
      }
      setState(() {
        _items.insert(
          0,
          LibraryItem(
            name: file.name,
            bytes: bytes,
            format: (report as PreflightReport).format,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Failures carry no text, so the wording lives here — where it can be
  /// translated with the rest of the application.
  static String _describe(DocumentFailure failure) => switch (failure) {
        UnsupportedFormatFailure(:final String extension) =>
          '.$extension is not supported',
        EncryptedDocumentFailure() => 'This document is password protected',
        CorruptDocumentFailure() => 'This file is damaged',
        TooLargeFailure() => 'This file is too large to open safely',
        SuspiciousArchiveFailure() => 'This archive looks unsafe',
        RendererFailure(:final bool timedOut) =>
          timedOut ? 'Rendering timed out' : 'The renderer stopped',
        NotFoundFailure() => 'The file could not be read',
        UnexpectedFailure() => 'Something went wrong',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackdrop(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(child: _Masthead(count: _items.length)),
              SliverList.separated(
                itemCount: _items.length,
                separatorBuilder: (BuildContext context, int index) =>
                    Container(
                  height: Dims.hairline,
                  margin: const EdgeInsetsDirectional.only(start: Dims.spine),
                  color: context.colors.hairline,
                ),
                itemBuilder: (BuildContext context, int index) =>
                    StaggeredEntrance(
                  index: index,
                  child: _EntryRow(
                    item: _items[index],
                    index: index + 1,
                    onOpen: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            ViewerScreen(item: _items[index]),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Space.giant)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _OpenBar(busy: _busy, onPressed: _pick),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.xl, Space.md, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('DOCUMENTS', style: context.texts.displayLarge),
          const SizedBox(height: Space.sm),
          Container(height: Dims.borderThick, color: context.colors.onSurface),
          const SizedBox(height: Space.xs),
          Row(
            children: <Widget>[
              Text('$count FILES', style: context.texts.labelSmall),
              Text('   ·   ', style: context.texts.labelSmall),
              Text(
                'FULLY OFFLINE',
                style: context.texts.labelSmall
                    ?.copyWith(color: context.colors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatefulWidget {
  const _EntryRow({
    required this.item,
    required this.index,
    required this.onOpen,
  });

  final LibraryItem item;
  final int index;
  final VoidCallback onOpen;

  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final Color spine = FormatBadge.colorOf(widget.item.format);

    return Pressable(
      onPressed: widget.onOpen,
      scale: 0.995,
      semanticLabel: widget.item.name,
      onPressChanged: (bool down) => setState(() => _down = down),
      child: ColoredBox(
        color: _down
            ? context.colors.surfaceSunken
            : const Color(0x00000000),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                width: _down ? Dims.spine * 2.2 : Dims.spine,
                color: spine,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.sm,
                    Space.md,
                    Space.md,
                    Space.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: Dims.indexColumn,
                        child: Text(
                          widget.index.toString().padLeft(2, '0'),
                          style: context.texts.labelSmall,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              widget.item.baseName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.titleLarge,
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              '${widget.item.extension}   ·   '
                              '${(widget.item.bytes.length / 1024).round()} KB',
                              style: context.texts.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenBar extends StatelessWidget {
  const _OpenBar({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: busy ? null : onPressed,
      scale: 0.99,
      semanticLabel: 'Open a document',
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceInverse,
          border: Border(
            top: BorderSide(
              color: context.colors.onSurface,
              width: Dims.borderThick,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (busy)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.onSurfaceInverse,
                    ),
                  )
                else
                  Icon(
                    Icons.north_east_rounded,
                    size: 18,
                    color: context.colors.onSurfaceInverse,
                  ),
                const SizedBox(width: Space.sm),
                Text(
                  'OPEN A DOCUMENT',
                  style: context.texts.labelLarge
                      ?.copyWith(color: context.colors.onSurfaceInverse),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
