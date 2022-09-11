import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const _template = """
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Colloscope</title>
    <style>
      @media print {
        .pagebreak {
          page-break-before: always;
        }
      }

      @page {
        padding: 5px 10px;
      }

      table {
        border-collapse: collapse;
      }

      th,
      td {
        border-bottom: 1px solid #ddd;
        page-break-inside: avoid !important;
      }

      .avoid-page-break {
        page-break-inside: avoid !important;
        margin: 2px 0 2px 0; /* to keep the page break from cutting too close to the text in the div */
      }

      th,
      td {
        padding: 2px;
      }

      td {
        text-align: center;
      }

      tr:nth-child(even) {
        background-color: #f2f2f2;
      }

      div.chip {
        display: inline-block;
        border: 1px solid black;
        border-radius: 4px;
        padding: 2px;
        margin: 2px;
        text-align: center;
      }

      /* STYLE */
    </style>
  </head>
  <body>
    <!-- BODY -->
  </body>
</html>
""";

String fillTemplate(List<String> pages, {String additionalStyle = ""}) {
  const pageBreaker = """
  <div class="pagebreak"> </div>
  """; // sync with <style>
  final body = pages.join(pageBreaker);
  const bodyMarker = "<!-- BODY -->";
  const styleMarker = "/* STYLE */";
  return _template
      .replaceFirst(bodyMarker, body)
      .replaceFirst(styleMarker, additionalStyle);
}

Future<String> saveDocument(String content, String name) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(join(directory.path, name));
  await file.writeAsString(content);
  return file.path;
}

String _colorToHTML(Color color) {
  return "rgba(${color.red}, ${color.green}, ${color.blue}, ${color.opacity})";
}

/// [colors] is the list of the colors class for each matieres
/// with name matiere-<index>
String cssMatieresColorDefinition(List<Color> colors) {
  final classes = List<String>.generate(
      colors.length,
      (index) =>
          ".matiere-$index { background-color: ${_colorToHTML(colors[index])}; }");
  return classes.join("\n");
}
