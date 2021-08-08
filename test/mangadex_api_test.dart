import 'dart:math';

import 'package:mangadex_api/mangadex_api.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' show load, env;

void main() {
  group('A group of tests', () {
    final client = MDClient();

    setUp(() async {
      load();

      // slow down for rate limit
      var rng = Random();
      await Future.delayed(Duration(seconds: rng.nextInt(2) + 3));
    });

    test('Get Individual Chapter Test', () async {
      var chapter =
          await client.getChapter('5e8bc984-5f3f-4fb1-b6ee-cf7f3812b112');
      expect(chapter!.title, 'Knihovna');
    });

    test('Get Chapter by Manga ID', () async {
      var chapter = await client.getChapter(null,
          mangaId: 'd7037b2a-874a-4360-8a7b-07f2899152fd');
      expect(chapter!.title, "Iruma-kun's Demon School");
    });

    test('Manga Test', () async {
      var manga = await client.getManga('a96676e5-8ae2-425e-b549-7f15dd34a6d8');
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
      expect(manga[0].title['jp'], 'Ijiranaide, Nagatoro-san');
    });

    test('Get User Test', () async {
      var user = await client.getUser('b60aca06-048f-4cb9-89c8-87ab2b0dc28f');
      expect(user!.username, 'hernik');
    });

    test('Get Group Test', () async {
      var group = await client.getGroup('790a3272-2a99-4df7-95d1-ee527351a3d0');
      expect(group!.name, 'Weebium');
    });

    test('Search Group Test', () async {
      var group = await client.searchGroups(name: 'Weebium');
      expect(group[0].leader.username, 'hernik');
    });

    test('Logged In User - Followed List Test', () async {
      await client.login('4lomega', env['MDPASS']!);
      var followed = await client.followedManga();
      expect(followed[0].title['jp'], 'Tensei Shitara Slime Datta Ken');
    });
  });
}
