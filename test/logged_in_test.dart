@Timeout(Duration(seconds: 60))
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

    test('Logged In User - Followed List Test', () async {
      await client.login('4lomega', env['MDPASS']!);
      var followed = await client.followedManga();
      expect(followed[1].title['en'], 'Tensei Shitara Slime Datta Ken');
    });

    test('Logged In User - Followed Groups Test', () async {
      await client.login('4lomega', env['MDPASS']!);
      var followed = await client.followedGroups();
      expect(followed[0].name, 'Tempest');
    });

    test('Logged In User - Followed Groups Test', () async {
      await client.login('4lomega', env['MDPASS']!);
      var followed = await client.followedGroups();
      expect(followed[0].name, 'Tempest');
    });

    test('Logged In User - Custom List Test', () async {
      await client.login('4lomega', env['MDPASS']!);
      var id = await client.createCustomList('testing list');
      await client.addToCustomList(id, 'c2390196-0ad7-4b90-9019-c23c000eec78');
      await Future.delayed(Duration(seconds: 2));
      await client.removeFromCustomList(
          id, 'c2390196-0ad7-4b90-9019-c23c000eec78');
      await client.deleteCustomList(id);
    });
  });
}
