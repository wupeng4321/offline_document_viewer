# Changelog

## 0.1.0

First release.

### Added

- `DocumentView` — renders a document with no chrome of its own.
- `DocumentViewController` — search, navigation, outline, status and typed
  failures, as a `ChangeNotifier`.
- `DocumentSource.file` / `.bytes` / `.asset`.
- `DocumentPreflight` — standalone validation you can run before showing UI.
- Sealed `DocumentFailure` hierarchy with `RecoveryHint`s and no user-facing
  strings, so wording stays with the host application.

### Formats

Nine formats, each verified rendering on a device.

- PDF through PDFium, natively.
- DOCX, XLSX, PPTX, XLS and CSV through bundled JavaScript engines.
- XLSX ships a custom `xl/styles.xml` parser covering borders, fonts,
  alignment, theme colours with tint and shade, merges, frozen panes and
  hidden rows and columns — none of which SheetJS Community Edition exposes.
- RTF is converted to HTML in Dart, preserving paragraphs, emphasis, colours,
  alignment and lists.
- DOC and PPT are read through a Dart OLE compound file reader and shown as
  text, labelled `textOnly`. Word's piece table is followed so mixed 8-bit and
  UTF-16 runs decode correctly; PowerPoint's slide masters, speaker notes and
  internal version stamps are skipped so only slide content is shown.

### Bundled engine fixes

Eight upstream defects are patched in the vendored engines; each is marked in
the source and documented in `THIRD_PARTY_NOTICES.md`.

- docx-preview: `themeFill` ignored, `themeTint`/`themeShade` not applied, and
  `w:val="auto"` overriding theme text colours.
- PPTXjs: bullet fonts not inherited from layout or master, `Wingdings`
  excluded from dingbat conversion, numeric XML character references left
  undecoded, a hard crash on a missing `docProps/app.xml`, and `numCol` /
  `vert` ignored.

### Layout

- Word pages, slides and spreadsheets are scaled to the viewport on render.
  Fixed-width documents otherwise read as broken on a phone rather than merely
  zoomed out.

### Compatibility

- Android Gradle Plugin 9 rejects a ProGuard file referenced by
  `flutter_inappwebview` 6.1.x. The dependency constraint is left open so an
  application can select the 6.2 line without this package forcing a
  pre-release on everyone; the README explains when to do so.

### Security

- Zip bomb, path traversal and entry-count checks that read the central
  directory without inflating anything.
- Strict per-platform Content Security Policy with `connect-src 'none'`.
- Navigation outside the document workspace refused.
- Android WebView renderer-process death contained and surfaced as a
  recoverable failure.
