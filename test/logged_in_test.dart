@Timeout(Duration(seconds: 60))
import 'dart:math';

import 'package:mangadex_api/mangadex_api.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' show load, env;

void main() {
  group('Logged-in User test', () {
    final client = MDClient();

    setUp(() async {
      load();

      // slow down for rate limit
      var rng = Random();
      await Future.delayed(Duration(seconds: rng.nextInt(3) + 3));
    });

    test('Followed List Test', () async {
      await client.login('4lomega', env['MDPASS']!);
      var followed = await client.followedManga();
      expect(followed[1].title['en'], 'Tensei Shitara Slime Datta Ken');
    });

    test('Followed Groups Test', () async {
      await client.login('4lomega', env['MDPASS']!);
      var followed = await client.followedGroups();
      expect(followed[0].name, 'Tempest');
      expect(followed[0].leader.roles[2], 'GROUP_LEADER');
    });

    test('Custom List Test', () async {
      await client.login('4lomega', env['MDPASS']!);
      var id = await client.createCustomList('testing list');
      await client.addToCustomList(id, 'c2390196-0ad7-4b90-9019-c23c000eec78');
      await Future.delayed(Duration(seconds: 2));
      await client.removeFromCustomList(
          id, 'c2390196-0ad7-4b90-9019-c23c000eec78');
      await client.deleteCustomList(id);
    });

    test('Update Manga Status Test', () async {
      await client.login('4lomega', env['MDPASS']!);
      await client.setReadingStatus(
          'e78a489b-6632-4d61-b00b-5206f5b8b22b', ReadingStatus.PAUSED);
    });

    test('Follow & Unfollow manga test', () async {
      await client.login('4lomega', env['MDPASS']!);
      await client.followManga('e78a489b-6632-4d61-b00b-5206f5b8b22b');
      await Future.delayed(Duration(seconds: 3));
      await client.unfollowManga('e78a489b-6632-4d61-b00b-5206f5b8b22b');
    });
  });
}
