import 'package:mangadex_api/mangadex_api.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final client = MDClient();

    setUp(() {
      // Additional setup goes here.
    });

    test('Chapter Test', () async {
      var chapter =
          await client.getChapter('5e8bc984-5f3f-4fb1-b6ee-cf7f3812b112');
      expect(chapter!.title, 'Knihovna');
    });

    test('Manga Test', () async {
      var manga =
          await client.getMangaInfo('a96676e5-8ae2-425e-b549-7f15dd34a6d8');
      expect(manga!.title['en'], 'Komi-san wa Komyushou Desu.');
    });

    test('Search Test', () async {
      var manga = await client.search(includedTags: [
        '423e2eae-a7a2-4a8b-ac03-a8351462d71d',
        'caaa44eb-cd40-4177-b930-79d3ef2afe87'
      ], status: [
        'ongoing'
      ], authors: [
        '7e552c08-f7cf-4e0e-9723-409d749dd77c'
      ]);
      expect(manga[0].title['en'], 'Ijiranaide, Nagatoro-san');
    });
  });
}
