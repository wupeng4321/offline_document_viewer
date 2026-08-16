# offline_document_viewer

[![pub package](https://img.shields.io/pub/v/offline_document_viewer.svg)](https://pub.dev/packages/offline_document_viewer)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![platforms](https://img.shields.io/badge/platforms-android%20%7C%20ios-lightgrey.svg)](https://pub.dev/packages/offline_document_viewer)

View **PDF, Word, Excel and PowerPoint** documents in Flutter — entirely on the
device. No server, no conversion API, no network permission. The rendering
engines ship inside the package.

```dart
DocumentView(source: DocumentSource.file('/path/to/report.xlsx'))
```

That is the whole minimum. The widget draws the document and nothing else —
no app bar, no toolbar, no page counter — so it drops into your design instead
of fighting it.

<p align="center">
  <img src="https://raw.githubusercontent.com/huseyiniriss/offline_document_viewer/main/doc/screenshots/library.png" width="24%" alt="A document library built on the package">
  <img src="https://raw.githubusercontent.com/huseyiniriss/offline_document_viewer/main/doc/screenshots/xlsx.png" width="24%" alt="A spreadsheet with borders, theme fills, rotated text and number formats">
  <img src="https://raw.githubusercontent.com/huseyiniriss/offline_document_viewer/main/doc/screenshots/pptx.png" width="24%" alt="Slides with theme colours, a gradient fill, preset geometries and bullets inherited from the layout">
  <img src="https://raw.githubusercontent.com/huseyiniriss/offline_document_viewer/main/doc/screenshots/docx.png" width="24%" alt="A Word document with headings, lists, a shaded table and an embedded image">
</p>

<p align="center"><sub>The example app. Everything except the document itself belongs to the app — the package contributes the rendering surface.</sub></p>

## Why this exists

Android has no system component that renders Office documents. The usual
workaround is a WebView pointed at Google Docs Viewer or Office Online, which
**requires an internet connection** and sends the document to a third party.
Commercial SDKs do work offline, but they are enterprise-priced and closed.

This package takes the third road: open-source engines, bundled, running on
the device.

## Supported formats

| Format | Fidelity | Engine |
| --- | --- | --- |
| `.pdf` | Full | PDFium, native — never touches the WebView |
| `.docx` `.docm` | High | docx-preview (patched) |
| `.xlsx` `.xlsm` | High | SheetJS + this package's own style layer |
| `.pptx` `.pptm` | High | PPTXjs (patched) |
| `.xls` | Values, no styling | SheetJS |
| `.csv` `.tsv` | Full | SheetJS |
| `.rtf` | Text and formatting | Converted to HTML in Dart |
| `.doc` `.ppt` | Text only, labelled | OLE compound file reader, in Dart |

Every one of these is verified rendering on a device, not just in unit tests.

`.rtf`, `.doc` and `.ppt` are handled entirely in Dart — no JavaScript engine
is involved. RTF keeps paragraphs, emphasis, colours, alignment and lists. The
two legacy binary formats have no open-source on-device layout engine, so they
are shown as text and say so: a clear text view beats a half-working fidelity
attempt, and `DocumentFormat.fidelity` reports `textOnly` so your UI can too.

### What Excel gets right that the underlying engine does not

SheetJS Community Edition reads cell **fills** but not borders, fonts or
alignment; those are a Pro feature. This package parses `xl/styles.xml`,
`xl/theme/theme1.xml` and the per-sheet style indices itself, so you get
border styles and weights, theme colours with tint and shade, the indexed
palette, bold/italic/underline/strike, super- and subscript, horizontal and
vertical alignment, wrapping, indent, rotated text, merged cells, column
widths, row heights, hidden rows and columns, and frozen panes.

## Installation

```yaml
dependencies:
  offline_document_viewer: ^0.1.0
```

No asset declarations, no platform channels to register — the engines and
fonts travel with the package.

### Android

`minSdkVersion 21` or higher.

> **If your project uses Android Gradle Plugin 9**, add this to your app's
> `pubspec.yaml`:
>
> ```yaml
> dependencies:
>   flutter_inappwebview: ^6.2.0-beta.3
> ```
>
> The 6.1.x line references a ProGuard file that AGP 9 rejects, which fails the
> build before your code is compiled. This package's constraint is deliberately
> left open so you are not forced onto a pre-release when you do not need one.

### iOS

iOS 12 or higher. No `Info.plist` entries are required — the package requests
no permissions and opens no network connections.

## Usage

### With your own chrome

```dart
final controller = DocumentViewController();

@override
void dispose() {
  controller.dispose();
  super.dispose();
}

DocumentView(
  source: DocumentSource.bytes(bytes, name: 'q3-report.pptx'),
  controller: controller,
  placeholderBuilder: (context) => const MySkeleton(),
  errorBuilder: (context, failure) => MyError(failure: failure),
  onReady: (info) => debugPrint('${info.unitCount} slides in ${info.renderDuration}'),
);

// elsewhere
await controller.search('revenue');   // '' clears the highlight
await controller.goTo(3);
controller.info?.outline;             // headings, sheet names, slide titles
```

`DocumentViewController` is a `ChangeNotifier`. Listen to it for `status`,
`position`, `searchHits`, `info` and `failure`.

### Sources

```dart
DocumentSource.file(path)                     // from disk
DocumentSource.bytes(bytes, name: 'a.docx')   // already in memory
DocumentSource.asset('assets/manual.pdf')     // from your bundle
```

Bytes are read once and copied into a private workspace, so a stale iOS
security-scoped bookmark or a revoked Android URI permission cannot break an
already-opened document.

### Failures are typed, not strings

```dart
errorBuilder: (context, failure) => Text(switch (failure) {
  EncryptedDocumentFailure() => 'This document is password protected',
  TooLargeFailure(:final sizeBytes) => 'Too large: $sizeBytes bytes',
  UnsupportedFormatFailure(:final extension) => '.$extension is not supported',
  _ => 'Could not open this document',
}),
```

`DocumentFailure` is sealed, so a `switch` over it is exhaustive. Each failure
also carries a `recovery` hint — retry, reselect the file, ask for a password,
open elsewhere — and no user-facing text, because wording and translation
belong to your app.

### Validate before you show any UI

```dart
final report = DocumentPreflight.inspect(bytes: bytes, fileName: name);
if (report is DocumentFailure) {
  // reject with your own message
}
```

## API

| Type | Purpose |
| --- | --- |
| `DocumentView` | The widget. `placeholderBuilder`, `errorBuilder`, `onReady`, `onFailure`, `renderTimeout` |
| `DocumentViewController` | `search()`, `goTo()`, plus `status`, `position`, `searchHits`, `info`, `failure` |
| `DocumentSource` | `.file()` · `.bytes()` · `.asset()` |
| `DocumentPreflight` | Standalone validation, with its limits exposed as constants |
| `DocumentFormat` | Detected format, its `fidelity` and `family` |
| `DocumentFailure` | Sealed failure hierarchy with `RecoveryHint` |

## Security

Documents are untrusted input, and the package treats them that way.

- **Preflight** runs before any engine sees the bytes: empty files, size caps,
  entry-count caps, path traversal, and zip bombs. The zip central directory
  is read by hand so declared sizes are checked **without inflating anything**.
- **No network.** The WebView that hosts the Office engines carries a strict
  Content Security Policy with `connect-src 'none'`, and every navigation
  outside the document's private workspace is refused. Remote references
  embedded in a document cannot phone home.
- **No loosened file access.** `allowFileAccessFromFileURLs` and
  `allowUniversalAccessFromFileURLs` stay off. On iOS the document bytes are
  streamed over the JavaScript bridge rather than fetched, precisely so those
  flags can remain disabled.
- **Renderer crashes are contained.** On Android an unhandled WebView
  renderer-process death takes the whole application down; it is intercepted
  and reported as a recoverable `RendererFailure`.

### How the bridge works

Android and iOS deliberately diverge:

- **Android** — `WebViewAssetLoader` serving the workspace from the virtual
  `https://appassets.androidplatform.net` origin. Google's own recommendation:
  a real origin keeps the same-origin policy intact.
- **iOS** — `WKWebView.loadFileURL` with read access scoped to the workspace.
  A custom scheme handler is **not** used: on iOS 26, WebKit terminates pages
  loaded through a custom scheme that contain scripts.

### Fitting the screen

Word pages, slides and spreadsheets are authored at a fixed width that is far
wider than a phone. Each is scaled down to the viewport on render, which keeps
every relationship in the document intact and leaves pinch-zoom available.
Without it a document reads as broken rather than merely zoomed out — columns
look misaligned and content appears to be missing.

Very wide spreadsheets stop scaling at 40% and scroll from there, so text
never becomes unreadably small.

## Size

Roughly 6 MB compressed. Most of that is fonts, and they are not optional:
Office documents size their text boxes using Calibri, Cambria and Arial
metrics, which exist on neither Android nor iOS. Without metric-compatible
substitutes text overflows its box and fixed-position layouts drift — the
difference is immediately visible, not cosmetic.

## Known limits

- Spreadsheets are cut off past 3000 rows rather than exhausting memory;
  `DocumentInfo.truncated` tells you when that happened.
- Charts, conditional formatting, data validation and pivot tables are not
  rendered.
- PowerPoint does not apply `normAutofit`, and long lines can still break
  mid-word.
- `.xls` gives you values without styling — the legacy format's style data is
  not readable by the bundled engine.
- Password-protected documents are detected and reported, not opened.

## Example

`example/` is a small document library: format badges, search, an outline
sheet and error copy, all built on `DocumentView`. It is the reference for how
the package expects to be used.

```bash
cd example && flutter run
```

## Contributing

Issues and pull requests are welcome. Before opening a PR:

```bash
flutter analyze          # must be clean, including public_member_api_docs
flutter test             # unit tests plus fixture and asset guards
./tool/check_js.sh       # parses the bundled JavaScript; needs Node
```

The bundled engines carry patches; each is marked `/* PATCH: */` in the source
and explained in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and `doc/`.
If you change one, record it there too — the licences require it.

## Licence

MIT, plus the bundled engines and fonts under their own licences. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) — **if you ship an app with
this package, you need to carry those notices.** The licence texts are bundled
as assets so you can show them from an about screen:

```dart
await rootBundle.loadString(
  'packages/offline_document_viewer/assets/licenses/LICENSE-liberation',
);
```
