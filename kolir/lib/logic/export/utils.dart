import 'dart:io';

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
        padding: 10px 20px;
      }

      table {
        border-collapse: collapse;
      }

      th,
      td {
        border-bottom: 1px solid #ddd;
      }

      th,
      td {
        padding: 10px;
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
      }
    </style>
  </head>
  <body>
    <!-- BODY -->
  </body>
</html>
""";

String fillTemplate(List<String> pages) {
  const pageBreaker = """
  <div class="pagebreak"> </div>
  """; // sync with <style>
  final body = pages.join(pageBreaker);
  const bodyMarker = "<!-- BODY -->";
  return _template.replaceAll(bodyMarker, body);
}

Future<String> saveDocument(String content, String name) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(join(directory.path, name));
  await file.writeAsString(content);
  return file.path;
}
