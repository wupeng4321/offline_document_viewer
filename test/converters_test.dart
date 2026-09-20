import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_document_viewer/src/engine/compound_file.dart';
import 'package:offline_document_viewer/src/engine/legacy_text.dart';
import 'package:offline_document_viewer/src/engine/rtf_converter.dart';

Uint8List _fixture(String name) =>
    File('test/fixtures/$name').readAsBytesSync();

Uint8List _rtf(String source) => Uint8List.fromList(source.codeUnits);

Uint8List _extendedDifatCompoundFile() {
  const int sectorSize = 512;
  const int fatSectorCount = 110;
  const int directorySector = 0;
  const int difatSector = 1;
  const int firstFatSector = 2;
  const int lastFatSector = firstFatSector + fatSectorCount - 1;
  const int endOfChain = 0xfffffffe;
  const int fatSector = 0xfffffffd;
  const int difatSectorMarker = 0xfffffffc;

  int sectorOffset(int sector) => sectorSize + sector * sectorSize;

  final Uint8List bytes = Uint8List(
    sectorSize + (lastFatSector + 1) * sectorSize,
  );
  final ByteData view = ByteData.sublistView(bytes);
  bytes.setRange(0, 8, const <int>[
    0xd0,
    0xcf,
    0x11,
    0xe0,
    0xa1,
    0xb1,
    0x1a,
    0xe1,
  ]);
  view
    ..setUint16(0x1e, 9, Endian.little)
    ..setUint32(0x2c, fatSectorCount, Endian.little)
    ..setUint32(0x30, directorySector, Endian.little)
    ..setUint32(0x38, 4096, Endian.little)
    ..setUint32(0x3c, endOfChain, Endian.little)
    ..setUint32(0x44, difatSector, Endian.little)
    ..setUint32(0x48, 1, Endian.little);

  for (int index = 0; index < 109; index++) {
    view.setUint32(0x4c + index * 4, firstFatSector + index, Endian.little);
  }

  final int difatOffset = sectorOffset(difatSector);
  bytes.fillRange(difatOffset, difatOffset + sectorSize, 0xff);
  view
    ..setUint32(difatOffset, lastFatSector, Endian.little)
    ..setUint32(difatOffset + sectorSize - 4, endOfChain, Endian.little);

  for (int sector = firstFatSector; sector <= lastFatSector; sector++) {
    final int offset = sectorOffset(sector);
    bytes.fillRange(offset, offset + sectorSize, 0xff);
  }
  final int fatOffset = sectorOffset(firstFatSector);
  view.setUint32(fatOffset, endOfChain, Endian.little);
  view.setUint32(fatOffset + difatSector * 4, difatSectorMarker, Endian.little);
  for (int sector = firstFatSector; sector <= lastFatSector; sector++) {
    view.setUint32(fatOffset + sector * 4, fatSector, Endian.little);
  }

  return bytes;
}

void main() {
  group('RTF', () {
    test('keeps paragraphs, emphasis and alignment', () {
      final String html = RtfConverter.toHtml(
        _rtf(r'{\rtf1\ansi \pard\qc\b Title\b0\par \pard Body \i word\i0 .\par}'),
      );
      expect(html, contains('text-align:center'));
      expect(html, contains('<strong>Title</strong>'));
      expect(html, contains('<em>word</em>'));
    });

    test('coalesces a run instead of wrapping every character', () {
      final String html =
          RtfConverter.toHtml(_rtf(r'{\rtf1\ansi \b bold text\b0\par}'));
      expect(html, contains('<strong>bold text</strong>'));
      // The naive implementation produced one wrapper per letter.
      expect(html.split('<strong>').length - 1, 1);
    });

    test('resolves colour indices against the auto entry', () {
      // The leading `;` is RTF's "auto" colour and occupies index 0, so the
      // first real colour is index 1.
      final String html = RtfConverter.toHtml(
        _rtf(
          r'{\rtf1\ansi{\colortbl ;\red192\green57\blue43;}'
          r'\cf1 red\cf0 plain\par}',
        ),
      );
      expect(html, contains('color:#c0392b'));
    });

    test('decodes unicode escapes and skips their fallback character', () {
      final String html =
          RtfConverter.toHtml(_rtf(r'{\rtf1\ansi \u351?rnek\par}'));
      expect(html, contains('şrnek'));
      expect(html, isNot(contains('?')));
    });

    test('drops metadata destinations', () {
      final String html = RtfConverter.toHtml(
        _rtf(r'{\rtf1\ansi{\fonttbl{\f0 Calibri;}}{\info{\author Someone}}Body\par}'),
      );
      expect(html, contains('Body'));
      expect(html, isNot(contains('Calibri')));
      expect(html, isNot(contains('Someone')));
    });

    test('survives malformed input without throwing', () {
      expect(
        () => RtfConverter.toHtml(_rtf(r'{\rtf1\ansi \b unclosed group')),
        returnsNormally,
      );
      expect(
        () => RtfConverter.toHtml(Uint8List.fromList(<int>[0xFF, 0x00, 0x7B])),
        returnsNormally,
      );
    });

    test('treats a backslash-newline as a paragraph mark', () {
      // Cocoa and TextEdit write breaks this way instead of `\par`.
      final String html =
          RtfConverter.toHtml(_rtf('{\\rtf1\\ansi First\\\nSecond\\\n}'));
      expect(html.split('<p').length - 1, 2);
    });

    test('reads a real file produced by another writer', () {
      final String html = RtfConverter.toHtml(_fixture('sample.rtf'));
      expect(html, contains('Madde bir'));
      expect(html, contains('ğüşiöç'));
      // The fixture has a heading, body text, two bullets and a centred line;
      // collapsing them into one block was a real regression.
      expect(html.split('<p').length - 1, greaterThan(3));
    });
  });

  group('compound file', () {
    test('enumerates the streams of a real .xls', () {
      final CompoundFile? cfb = CompoundFile.parse(_fixture('sample.xls'));
      expect(cfb, isNotNull);
      expect(cfb!.streamNames, contains('Workbook'));
    });

    test('returns null for anything that is not a compound file', () {
      expect(CompoundFile.parse(_fixture('sample.xlsx')), isNull);
      expect(CompoundFile.parse(Uint8List(16)), isNull);
    });

    test('reads a stream back', () {
      final CompoundFile cfb = CompoundFile.parse(_fixture('sample.xls'))!;
      final Uint8List? workbook = cfb.read('Workbook');
      expect(workbook, isNotNull);
      expect(workbook!.length, greaterThan(0));
      expect(cfb.read('NoSuchStream'), isNull);
    });

    test('stops an extended DIFAT after the declared FAT sector count', () {
      final CompoundFile? cfb = CompoundFile.parse(
        _extendedDifatCompoundFile(),
      );

      expect(cfb, isNotNull);
      expect(cfb!.streamNames, isEmpty);
    });
  });

  group('legacy text extraction', () {
    test('pulls paragraphs out of a real .doc', () {
      final List<String> paragraphs =
          LegacyTextExtractor.extractDoc(_fixture('sample.doc'));
      expect(paragraphs, isNotEmpty);
      final String text = paragraphs.join(' ');
      expect(text, contains('Madde bir'));
      // Turkish characters arriving as digits and punctuation is the
      // signature of UTF-16 text being read one byte at a time.
      expect(text, contains('ğüşiöç'));
      expect(text, isNot(contains('kal1n')));
    });

    test('reads slide text from a .ppt, skipping master and notes', () {
      final List<String> lines =
          LegacyTextExtractor.extractPpt(_fixture('sample.ppt'));
      expect(lines, isNotEmpty);
      // Master placeholders and PowerPoint's internal version stamps are not
      // content and must not leak into the output.
      expect(
        lines.any((String l) => l.contains('Click to edit Master')),
        isFalse,
      );
      expect(lines.any((String l) => l.startsWith('___PPT')), isFalse);
      expect(lines, contains('ğüşiöçİĞÜŞÖÇ'));
    });

    test('returns nothing rather than throwing on a non-doc', () {
      expect(
        LegacyTextExtractor.extractDoc(_fixture('sample.xlsx')),
        isEmpty,
      );
      expect(LegacyTextExtractor.extractPpt(Uint8List(600)), isEmpty);
    });
  });
}
