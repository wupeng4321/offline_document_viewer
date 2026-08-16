import 'package:flutter/material.dart';
import 'package:offline_document_viewer/offline_document_viewer.dart';

import '../design/app_theme.dart';
import '../design/component.dart';
import '../design/pressable.dart';
import '../widgets/format_badge.dart';
import 'library_screen.dart';

/// Shows one document.
///
/// Everything visible here except the document itself belongs to the app:
/// the bar, the outline sheet, the search field and the error copy. The
/// package contributes [DocumentView] and the controller behind it.
class ViewerScreen extends StatefulWidget {
  const ViewerScreen({required this.item, super.key});

  final LibraryItem item;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final DocumentViewController _controller = DocumentViewController();
  final TextEditingController _query = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    _query.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) {
      _query.clear();
      _controller.search('');
    }
  }

  Future<void> _showOutline(List<String> outline) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (BuildContext sheetContext) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: outline.length,
          itemBuilder: (BuildContext context, int index) => Pressable(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _controller.goTo(index);
            },
            scale: 0.995,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.sm,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: Dims.spine,
                    height: 20,
                    margin: const EdgeInsets.only(right: Space.sm),
                    color: FormatBadge.colorOf(widget.item.format),
                  ),
                  Expanded(
                    child: Text(
                      outline[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: sheetContext.texts.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceSunken,
      // The chrome sits in the layout flow rather than over the document: on
      // iOS a platform view stacked under another layer fails to composite.
      body: Column(
        children: <Widget>[
          _Chrome(
            item: widget.item,
            controller: _controller,
            searching: _searching,
            query: _query,
            onToggleSearch: _toggleSearch,
            onShowOutline: _showOutline,
          ),
          Expanded(
            child: DocumentView(
              source: DocumentSource.bytes(
                widget.item.bytes,
                name: widget.item.name,
              ),
              controller: _controller,
              placeholderBuilder: (BuildContext context) =>
                  const _Skeleton(),
              errorBuilder: (BuildContext context, DocumentFailure failure) =>
                  _Failure(failure: failure, format: widget.item.format),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.item,
    required this.controller,
    required this.searching,
    required this.query,
    required this.onToggleSearch,
    required this.onShowOutline,
  });

  final LibraryItem item;
  final DocumentViewController controller;
  final bool searching;
  final TextEditingController query;
  final VoidCallback onToggleSearch;
  final void Function(List<String>) onShowOutline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.onSurface,
            width: Dims.borderThick,
          ),
        ),
      ),
      child: SizedBox(
        height: Dims.viewerChromeHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: Dims.spine,
              color: FormatBadge.colorOf(item.format),
            ),
            Expanded(
              child: searching
                  ? _SearchRow(
                      controller: query,
                      onChanged: controller.search,
                      onClose: onToggleSearch,
                    )
                  : ListenableBuilder(
                      listenable: controller,
                      builder: (BuildContext context, Widget? _) {
                        final DocumentInfo? info = controller.info;
                        return _TitleRow(
                          item: item,
                          info: info,
                          onSearch: onToggleSearch,
                          onOutline: info != null && info.outline.length > 1
                              ? () => onShowOutline(info.outline)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.item,
    required this.info,
    required this.onSearch,
    required this.onOutline,
  });

  final LibraryItem item;
  final DocumentInfo? info;
  final VoidCallback onSearch;
  final VoidCallback? onOutline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Pressable(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.sm),
            child: Icon(Icons.arrow_back_rounded, size: 22),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.baseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                <String>[
                  item.extension,
                  FormatBadge.fidelityLabel(item.format.fidelity),
                  if (info != null) '${info!.unitCount}',
                ].join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelSmall,
              ),
            ],
          ),
        ),
        if (onOutline != null)
          Pressable(
            onPressed: onOutline,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: Space.sm),
              child: Icon(Icons.format_list_numbered_rounded, size: 20),
            ),
          ),
        Pressable(
          onPressed: onSearch,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.md),
            child: Icon(Icons.search_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(width: Space.md),
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            onChanged: onChanged,
            cursorColor: context.colors.accent,
            style: context.texts.bodyLarge,
            decoration: InputDecoration(
              hintText: 'SEARCH IN DOCUMENT',
              hintStyle: context.texts.labelSmall,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        Pressable(
          onPressed: onClose,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.md),
            child: Icon(Icons.close_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  static const List<double> _widths = <double>[
    0.55, 0.94, 0.88, 0.92, 0.4, 0, 0.96, 0.96, 0.72,
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.documentSurface,
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final double width in _widths)
              if (width == 0)
                const SizedBox(height: Space.lg)
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: FractionallySizedBox(
                    widthFactor: width,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0x22000000)),
                      child: SizedBox(height: 14),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.failure, required this.format});

  final DocumentFailure failure;
  final DocumentFormat format;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FormatBadge(format: format, size: Dims.stampLarge, tilt: -6),
              const SizedBox(height: Space.xl),
              Text(
                _title(failure),
                textAlign: TextAlign.center,
                style: context.texts.headlineMedium,
              ),
              const SizedBox(height: Space.sm),
              Text(
                _hint(failure.recovery),
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _title(DocumentFailure failure) => switch (failure) {
        UnsupportedFormatFailure(:final String extension) =>
          '.$extension is not supported',
        EncryptedDocumentFailure() => 'Password protected',
        CorruptDocumentFailure() => 'This file is damaged',
        TooLargeFailure() => 'Too large to open safely',
        SuspiciousArchiveFailure() => 'This archive looks unsafe',
        RendererFailure() => 'Could not render this document',
        NotFoundFailure() => 'File not found',
        UnexpectedFailure() => 'Something went wrong',
      };

  static String _hint(RecoveryHint hint) => switch (hint) {
        RecoveryHint.none => '',
        RecoveryHint.retry => 'Try opening it again.',
        RecoveryHint.reselectFile => 'Pick the file again.',
        RecoveryHint.enterPassword => 'Passwords are not supported yet.',
        RecoveryHint.openElsewhere => 'Try another application.',
      };
}
