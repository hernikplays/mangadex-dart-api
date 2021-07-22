import 'package:mangadex_api/mangadex_api.dart';

void main() {
  // the "I don't want to use async function" way
  var client = MDClient();
  client.login('user', 'pass').then((v) {
    client.getChapter('5e8bc984-5f3f-4fb1-b6ee-cf7f3812b112').then((chapter) {
      print(chapter!.title);
    });

    client.getManga('a96676e5-8ae2-425e-b549-7f15dd34a6d8',
        appendChapters: true, translatedLang: ['cs']).then((m) {
      print(m!.title['en']);
    });

    client.getCovers('a96676e5-8ae2-425e-b549-7f15dd34a6d8').then((covers) {
      print(covers![covers.length - 1]);
    });

    client.search(
        mangaTitle: 'Nagatoro',
        authors: ['7e552c08-f7cf-4e0e-9723-409d749dd77c']).then((res) {
      print(res[0].title);
    });

    client.getGroup('790a3272-2a99-4df7-95d1-ee527351a3d0').then((group) {
      print(group!.name);
    });

    client.searchGroups(name: 'Weebium').then((group) {
      print(group[0].leader.username);
    });

    client.getMangaFeed().then((value) {
      print(value[0].chapter);
    });
  });
}
