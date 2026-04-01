import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> saveAndShareFile(String fileName, String content) async {
  final parts = [content.toJS].toJS;
  final blob = web.Blob(parts);
  final url = web.URL.createObjectURL(blob);
  
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  
  web.URL.revokeObjectURL(url);
}
