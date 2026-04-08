import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> downloadBytesWeb(String fileName, List<int> bytes) async {
  final uint8List = Uint8List.fromList(bytes);
  final parts = [uint8List.toJS].toJS;
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
