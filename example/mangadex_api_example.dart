import 'package:mangadex_api/mangadex_api.dart';

void main() {
  // Example usage of some functions
  var client = MDClient();
  client.login('user', 'pass').then((v) {
    client
        .getChapter(null, mangaId: 'd7037b2a-874a-4360-8a7b-07f2899152fd')
        .then((chapter) {
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
      print(value[0].chapterNum);
    });
  });
}
