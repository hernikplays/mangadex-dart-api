import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mangadex_api/src/classes.dart';

/// Main class containing all the communication with the API
class MDClient {
  /// Token for API authentication
  String token;

  /// Refresh token for refreshing the auth token
  String refresh;

  MDClient({this.token = '', this.refresh = ''});

  /// Gets the JWT and refresh token through the API
  ///
  /// Will throw an [Exception] if the password and user do not match OR API returns a 400
  ///
  /// ```dart
  /// var client = MDClient()
  /// client.login('myuser','mypassword')
  /// ```
  void login(String username, String password) {
    http.post(Uri.parse('https://api.mangadex.org/auth/login'),
        body: '{"username":"$username","password":"$password"}',
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
        }).then((res) {
      if (res.statusCode == 401) {
        throw 'User and Password does not match';
      } else if (res.statusCode == 400) {
        throw 'Bad request';
      }
      var data = jsonDecode(res.body);
      token = data['token']['session'];
      refresh = data['token']['refresh'];
    });
  }

  /// Refreshes the auth token using the saved refresh token
  void refreshToken() {
    if (token == '' || refresh == '') {
      throw 'Missing auth token or refresh token, make sure you logged in through the [login] function.';
    }
    http.post(Uri.parse('https://api.mangadex.org/auth/refresh'),
        body: '"token":"$refresh"',
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
        }).then((res) {
      var data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        token = data['token']['session'];
        refresh = data['token']['refresh'];
      } else {
        throw 'An error has happened: ${data["errors"][0]["title"]} - ${data["errors"][0]["detail"]}';
      }
    });
  }

  void solveCaptcha() {} // TODO: complete captcha system

  /// Gets the chapter specified by the UUID
  ///
  /// Returns [Null] if no chapters found
  Future<Chapter?> getChapter(String uuid) async {
    var res;
    if (token != '') {
      res = await http.get(Uri.parse('https://api.mangadex.org/chapter/$uuid'),
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'});
    } else {
      res = await http.get(Uri.parse('https://api.mangadex.org/chapter/$uuid'));
    }

    if (res.statusCode == 404) {
      return null;
    }

    var data = jsonDecode(res.body)['data'];

    // get MD@H URL
    var md = await http.get(
        Uri.parse("https://api.mangadex.org/at-home/server/${data['id']}"));
    var atHomeURL = jsonDecode(md.body)['baseUrl'];

    // create chapter URL
    // ignore: omit_local_variable_types
    List<String> normalChapter = [];
    for (var chapter in data['attributes']['data']) {
      normalChapter
          .add('$atHomeURL/data/${data["attributes"]["hash"]}/$chapter');
    }

    // create data-saver URL
    // ignore: omit_local_variable_types
    List<String> saverChapter = [];
    for (var chapter in data['attributes']['data']) {
      saverChapter
          .add('$atHomeURL/data-saver/${data["attributes"]["hash"]}/$chapter');
    }
    var chapter = Chapter(
        id: data['id'],
        title: data['attributes']['title'],
        volume: data['attributes']['volume'],
        chapter: data['attributes']['chapter'],
        translatedLanguage: data['attributes']['translatedLanguage'],
        chapterURLs: normalChapter,
        dataSaverChapterURLs: saverChapter,
        createdAt: data['attributes']['createdAt'],
        updatedAt: data['attributes']['updatedAt'],
        groupIds: data['attributes']['groups'],
        mangaId: data['attributes']['manga'],
        uploader: data['attributes']['uploader']);
    return chapter;
  }

  /// Gets information about manga
  ///
  /// If [appendChapters] is [true], returns available chapters in `.chapters`
  /// If there are no chapters available or [appendChapters] is [false], `.chapters` returns an empty [Map]
  /// If appending chapters, [translatedLang] should be either an empty [Array] (which will append chapters of all languages) or filled with codes of desired languages
  ///
  /// Returns [Null] if no manga can be found
  Future<Manga?> getMangaInfo(String uuid,
      {bool appendChapters = false,
      List<String> translatedLang = const []}) async {
    var res;
    if (token != '') {
      res = await http.get(Uri.parse('https://api.mangadex.org/manga/$uuid'),
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'});
    } else {
      res = await http.get(Uri.parse('https://api.mangadex.org/manga/$uuid'));
    }

    var data = jsonDecode(res.body)['data'];

    // ignore: omit_local_variable_types
    Map<String, dynamic> chapters = {};
    // append available chapters from other API endpoint
    if (appendChapters) {
      var chres = await http
          .get(Uri.parse('https://api.mangadex.org/manga/$uuid/aggregate'));
      chapters = Map.from(jsonDecode(chres.body)['volumes']);
    }
    var covers = await getCovers(uuid);
    var manga = Manga(
        altTitles: data['attributes']['altTitles'],
        title: Map.from(data['attributes']['title']),
        tags: data['attributes']['tags'],
        description: Map.from(data['attributes']['description']),
        isLocked: data['attributes']['isLocked'],
        links: (data['attributes']['links'] == null)
            ? null
            : Map.from(data['attributes']['links']),
        originalLang: data['attributes']['originalLanguage'],
        lastChapter: data['attributes']['lastChapter'],
        lastVolume: data['attributes']['lastVolume'],
        demographic: data['attributes']['publicationDemographic'],
        status: data['attributes']['status'],
        releaseYear: data['attributes']['year'],
        contentRating: data['attributes']['contentRating'],
        createdAt: data['attributes']['createdAt'],
        updatedAt: data['attributes']['updatedAt'],
        id: data['id'],
        chapters: chapters,
        covers: covers!);
    return manga;
  }

  /// Gets `10` of available cover images for a manga
  ///
  /// Returns [Null] if no found
  Future<List<String>?> getCovers(String mangaUuid) async {
    var res;
    if (token != '') {
      res = await http.get(
          Uri.parse('https://api.mangadex.org/cover?manga[]=$mangaUuid'),
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'});
    } else {
      res = await http
          .get(Uri.parse('https://api.mangadex.org/cover?manga[]=$mangaUuid'));
    }
    if (res.statusCode == 404) {
      return null;
    }
    var data = jsonDecode(res.body)['results'];

    // ignore: omit_local_variable_types
    List<String> covers = [];
    for (var item in data) {
      covers.add(
          'https://uploads.mangadex.org/covers/$mangaUuid/${item["data"]["attributes"]["fileName"]}');
    }
    return covers;
  }

  /// Search for manga
  ///
  /// Optional arguments are `mangaName` ([String]), `authors`, `includedTags`, `excludedTags`, `status` & `demographic` ( All [List<String>])
  /// **`status` MUST BE ONE OF `["ongoing","completed","hiatus","cancelled"]`**
  /// For more info see [the official documentation](https://api.mangadex.org/docs.html#operation/get-search-manga)
  ///
  /// Throws [Exception] if the server returns a 404 error
  ///
  /// Returns an empty [List<String>] if no results
  Future<List<Manga>> search(
      {String mangaTitle = '',
      List<String> authors = const [],
      List<String> includedTags = const [],
      List<String> excludedTags = const [],
      List<String> status = const [],
      List<String> demographic = const []}) async {
    var res;
    if (token != '') {
      res = await http.get(
          Uri.parse(
              'https://api.mangadex.org/manga?title=$mangaTitle${(authors.isNotEmpty) ? '&authors[]=${authors.join('&authors[]=')}' : ''}${(includedTags.isNotEmpty) ? '&includedTags[]=${includedTags.join('&includedTags[]=')}' : ''}${(excludedTags.isNotEmpty) ? '&excludedTags[]=${excludedTags.join('&excludedTags[]=')}' : ''}${(status.isNotEmpty) ? '&status[]=${status.join('&status[]=')}' : ''}${(demographic.isNotEmpty) ? '&publicationDemographic[]=${demographic.join('&publicationDemographic[]=')}' : ''}'),
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'});
    } else {
      res = await http.get(Uri.parse(
          'https://api.mangadex.org/manga?title=$mangaTitle${(authors.isNotEmpty) ? '&authors[]=${authors.join('&authors[]=')}' : ''}${(includedTags.isNotEmpty) ? '&includedTags[]=${includedTags.join('&includedTags[]=')}' : ''}${(excludedTags.isNotEmpty) ? '&excludedTags[]=${excludedTags.join('&excludedTags[]=')}' : ''}${(status.isNotEmpty) ? '&status[]=${status.join('&status[]=')}' : ''}${(demographic.isNotEmpty) ? '&publicationDemographic[]=${demographic.join('&publicationDemographic[]=')}' : ''}'));
    }
    var data = jsonDecode(res.body);
    if (res.statusCode == 400) {
      throw 'Error: ${data["errors"][0]["title"]} - ${data["errors"][0]["detail"]}';
    }
    List<Manga>? results = [];
    for (var manga in data['results']) {
      var r = manga['data'];
      results.add(Manga(
          altTitles: r['attributes']['altTitles'],
          title: Map.from(r['attributes']['title']),
          tags: r['attributes']['tags'],
          description: Map.from(r['attributes']['description']),
          isLocked: r['attributes']['isLocked'],
          links: (r['attributes']['links'] == null)
              ? null
              : Map.from(r['attributes']['links']),
          originalLang: r['attributes']['originalLanguage'],
          lastChapter: r['attributes']['lastChapter'],
          lastVolume: r['attributes']['lastVolume'],
          demographic: r['attributes']['publicationDemographic'],
          status: r['attributes']['status'],
          releaseYear: r['attributes']['year'],
          contentRating: r['attributes']['contentRating'],
          createdAt: r['attributes']['createdAt'],
          updatedAt: r['attributes']['updatedAt'],
          id: r['id']));
    }
    return results;
  }
}
