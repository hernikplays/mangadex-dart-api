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
  });
}
