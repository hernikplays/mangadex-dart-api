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
      var followed = await client.followedManga();
      expect(followed[0].title['jp'], 'Tensei Shitara Slime Datta Ken');
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
      await client.deleteCustomList(id);
    });
  });
}
