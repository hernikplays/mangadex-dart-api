import 'package:mangadex_api/mangadex_api.dart';

void main() {
  var client = MDClient();

  client.getChapter('5e8bc984-5f3f-4fb1-b6ee-cf7f3812b112').then((chapter) {
    print(chapter!.title);
  });

  client.getMangaInfo('a96676e5-8ae2-425e-b549-7f15dd34a6d8',
      appendChapters: true, translatedLang: ['cs']).then((m) {
    print(m!.title['en']);
  });
}
