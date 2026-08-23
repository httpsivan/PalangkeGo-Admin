import 'dart:convert';
import 'dart:typed_data';

import 'platform_file_saver.dart';

String _xml(String value) =>
    const HtmlEscape(HtmlEscapeMode.element).convert(value);

void downloadBytes(Uint8List bytes, String filename, String mimeType) {
  saveFileBytes(bytes: bytes, filename: filename, mimeType: mimeType);
}

Uint8List buildSimplePdf({
  required String title,
  required List<String> lines,
}) {
  final pages = <List<String>>[];
  for (var index = 0; index < lines.length; index += 32) {
    pages.add(lines.skip(index).take(32).toList());
  }
  if (pages.isEmpty) pages.add(const []);

  final objects = <String>[];
  final pageIds = <int>[];
  objects.add('<< /Type /Catalog /Pages 2 0 R >>');
  objects.add('');
  final fontId = 3;
  objects.add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
  for (final page in pages) {
    final pageId = objects.length + 1;
    final contentId = pageId + 1;
    pageIds.add(pageId);
    final stream = StringBuffer('BT\n/F1 13 Tf\n40 790 Td\n');
    stream.writeln('(${_pdfText(title)}) Tj');
    stream.writeln('/F1 8 Tf');
    stream.writeln('0 -22 Td');
    for (final line in page) {
      stream.writeln('(${_pdfText(line)}) Tj');
      stream.writeln('0 -17 Td');
    }
    stream.write('ET');
    final content = stream.toString();
    objects.add(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
      '/Resources << /Font << /F1 $fontId 0 R >> >> '
      '/Contents $contentId 0 R >>',
    );
    objects.add(
        '<< /Length ${utf8.encode(content).length} >>\nstream\n$content\nendstream');
  }
  final kids = pageIds.map((id) => '$id 0 R').join(' ');
  objects[1] = '<< /Type /Pages /Kids [$kids] /Count ${pageIds.length} >>';

  final output = BytesBuilder();
  output.add(utf8.encode('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'));
  final offsets = <int>[];
  for (var index = 0; index < objects.length; index++) {
    offsets.add(output.length);
    output.add(utf8.encode('${index + 1} 0 obj\n${objects[index]}\nendobj\n'));
  }
  final xrefOffset = output.length;
  output.add(utf8.encode('xref\n0 ${objects.length + 1}\n'));
  output.add(utf8.encode('0000000000 65535 f \n'));
  for (final offset in offsets) {
    output.add(utf8.encode('${offset.toString().padLeft(10, '0')} 00000 n \n'));
  }
  output.add(utf8.encode(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF'));
  return output.toBytes();
}

String _pdfText(String value) => value
    .replaceAll('₱', 'PHP ')
    .replaceAll('–', '-')
    .replaceAll('—', '-')
    .replaceAll('•', '-')
    .replaceAll('\\', '\\\\')
    .replaceAll('(', '\\(')
    .replaceAll(')', '\\)');

Uint8List buildSalesWorkbook({
  required List<List<Object?>> summaryRows,
  required List<List<Object?>> transactionRows,
}) {
  final entries = <_ZipEntry>[
    _ZipEntry('[Content_Types].xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>'''),
    _ZipEntry('_rels/.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>'''),
    _ZipEntry('xl/workbook.xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets><sheet name="Sales Summary" sheetId="1" r:id="rId1"/><sheet name="Sales Transactions" sheetId="2" r:id="rId2"/></sheets>
</workbook>'''),
    _ZipEntry('xl/_rels/workbook.xml.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
</Relationships>'''),
    _ZipEntry('xl/worksheets/sheet1.xml', _sheetXml(summaryRows, widths: 28)),
    _ZipEntry(
        'xl/worksheets/sheet2.xml', _sheetXml(transactionRows, widths: 20)),
  ];
  return _zip(entries);
}

String _sheetXml(List<List<Object?>> rows, {required double widths}) {
  final buffer =
      StringBuffer('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>
<cols><col min="1" max="30" width="$widths" customWidth="1"/></cols><sheetData>''');
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex];
    buffer.write('<row r="${rowIndex + 1}">');
    for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
      final value = row[columnIndex];
      final cell = '${_columnName(columnIndex)}${rowIndex + 1}';
      if (value is num) {
        buffer.write('<c r="$cell"><v>$value</v></c>');
      } else {
        buffer
            .write('<c r="$cell" t="inlineStr"><is><t>${_xml('${value ?? ''}')}'
                '</t></is></c>');
      }
    }
    buffer.write('</row>');
  }
  buffer.write('</sheetData></worksheet>');
  return buffer.toString();
}

String _columnName(int index) {
  var value = index + 1;
  var result = '';
  while (value > 0) {
    final remainder = (value - 1) % 26;
    result = String.fromCharCode(65 + remainder) + result;
    value = (value - remainder - 1) ~/ 26;
  }
  return result;
}

class _ZipEntry {
  const _ZipEntry(this.name, this.content);
  final String name;
  final String content;
}

Uint8List _zip(List<_ZipEntry> entries) {
  final output = BytesBuilder();
  final central = BytesBuilder();
  var offset = 0;
  for (final entry in entries) {
    final name = utf8.encode(entry.name);
    final data = Uint8List.fromList(utf8.encode(entry.content));
    final crc = _crc32(data);
    final localOffset = offset;
    final local = BytesBuilder();
    _u32(local, 0x04034b50);
    _u16(local, 20);
    _u16(local, 0);
    _u16(local, 0);
    _u16(local, 0);
    _u16(local, 0);
    _u32(local, crc);
    _u32(local, data.length);
    _u32(local, data.length);
    _u16(local, name.length);
    _u16(local, 0);
    local.add(name);
    local.add(data);
    final localBytes = local.takeBytes();
    output.add(localBytes);
    offset += localBytes.length;

    _u32(central, 0x02014b50);
    _u16(central, 20);
    _u16(central, 20);
    _u16(central, 0);
    _u16(central, 0);
    _u16(central, 0);
    _u16(central, 0);
    _u32(central, crc);
    _u32(central, data.length);
    _u32(central, data.length);
    _u16(central, name.length);
    _u16(central, 0);
    _u16(central, 0);
    _u16(central, 0);
    _u16(central, 0);
    _u32(central, 0);
    _u32(central, localOffset);
    central.add(name);
  }
  final centralBytes = central.takeBytes();
  output.add(centralBytes);
  _u32(output, 0x06054b50);
  _u16(output, 0);
  _u16(output, 0);
  _u16(output, entries.length);
  _u16(output, entries.length);
  _u32(output, centralBytes.length);
  _u32(output, offset);
  _u16(output, 0);
  return output.toBytes();
}

void _u16(BytesBuilder builder, int value) {
  builder.add(Uint8List.fromList([value & 0xff, (value >> 8) & 0xff]));
}

void _u32(BytesBuilder builder, int value) {
  builder.add(Uint8List.fromList([
    value & 0xff,
    (value >> 8) & 0xff,
    (value >> 16) & 0xff,
    (value >> 24) & 0xff,
  ]));
}

int _crc32(Uint8List data) {
  var crc = 0xffffffff;
  for (final byte in data) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
