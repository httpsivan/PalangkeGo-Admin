import 'dart:convert';
import 'package:csv/csv.dart';

String buildCsv(List<List<Object?>> rows) =>
    const ListToCsvConverter().convert(rows);
String csvDataUri(String csv) =>
    'data:text/csv;charset=utf-8,${Uri.encodeComponent(utf8.decode(utf8.encode(csv)))}';
