import 'web_downloader_stub.dart'
    if (dart.library.html) 'web_downloader_web.dart';

Future<void> downloadWebFile(String fileName, List<int> bytes) async {
  await downloadBytesWeb(fileName, bytes);
}
