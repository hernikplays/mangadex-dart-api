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

  /// Helper function for generating chapter URL
  Future<Map<String, List<String>>> generateChapter(r) async {
    // get MD@H URL
    var md = await http.get(
        Uri.parse("https://api.mangadex.org/at-home/server/${r['id']}"),
        headers: {HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'});
    var atHomeURL = jsonDecode(md.body)['baseUrl'];

    // create chapter URL
    var normalChapter = <String>[];
    for (var chapter in r['attributes']['data']) {
      normalChapter.add('$atHomeURL/data/${r["attributes"]["hash"]}/$chapter');
    }

    // create data-saver URL
    var saverChapter = <String>[];
    for (var chapter in r['attributes']['data']) {
      saverChapter
          .add('$atHomeURL/data-saver/${r["attributes"]["hash"]}/$chapter');
    }
    return {'normal': normalChapter, 'saver': saverChapter};
  }

  /// Gets the JWT and refresh token through the API
  ///
  /// Will throw an [Exception] if the password and user do not match OR API returns a 400
  ///
  /// ```dart
  /// var client = MDClient()
  /// client.login('myuser','mypassword')
  /// ```
  Future<void> login(String username, String password) async {
    var res = await http.post(Uri.parse('https://api.mangadex.org/auth/login'),
        body: '{"username":"$username","password":"$password"}',
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
        });
    if (res.statusCode == 401) {
      throw 'User and Password does not match';
    } else if (res.statusCode == 400) {
      throw 'Bad request';
    }
    var data = jsonDecode(res.body);

    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'].toString(),
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }

    token = data['token']['session'];
    refresh = data['token']['refresh'];
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

  /// Sends the captcha result to the API server
  ///
  /// Automatically sends your session token if you are logged in
  ///
  /// Throws an Exception if the captcha was solved incorrrectly
  Future<void> solveCaptcha(String captchaResult) async {
    var res;
    if (token != '') {
      res = await http.post(
        Uri.parse('https://api.mangadex.org/auth/solve'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
        },
        body: '{"captchaChallenge":"$captchaResult"}',
      );
    } else {
      res = await http.post(Uri.parse('https://api.mangadex.org/auth/solve'),
          body: '{"captchaChallenge":"$captchaResult"}',
          headers: {HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'});
    }
    var data = jsonDecode(res.body);
    if (res.statusCode == 400) {
      throw 'An error has happened: ${data["errors"][0]["title"]} - ${data["errors"][0]["detail"]}';
    }
  }

  /// Gets the chapter specified by the UUID
  ///
  /// Returns [Null] if no chapters found
  Future<Chapter?> getChapter(String uuid, {bool useLogin = false}) async {
    var res;
    if (token != '' && useLogin) {
      res = await http
          .get(Uri.parse('https://api.mangadex.org/chapter/$uuid'), headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
      });
    } else {
      res = await http.get(Uri.parse('https://api.mangadex.org/chapter/$uuid'),
          headers: {HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'});
    }

    if (res.statusCode == 404) {
      return null;
    }

    var data = jsonDecode(res.body)['data'];
    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'],
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }

    var getme = await generateChapter(data);
    var normalChapter = getme['normal']!;
    var saverChapter = getme['saver']!;

    var chapter = Chapter(
        id: data['id'],
        title: data['attributes']['title'],
        volumeNum: data['attributes']['volume'],
        chapterNum: data['attributes']['chapter'],
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
  Future<Manga?> getManga(String uuid,
      {bool appendChapters = false,
      List<String> translatedLang = const [],
      bool useLogin = false}) async {
    var res;
    if (token != '' && useLogin) {
      res = await http.get(
          Uri.parse(
              'https://api.mangadex.org/manga/$uuid?includes[]=cover_art&includes[]=author&includes[]=artist'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
            HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
          });
    } else {
      res = await http.get(
          Uri.parse(
              'https://api.mangadex.org/manga/$uuid?includes[]=cover_art&includes[]=author&includes[]=artist'),
          headers: {HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'});
    }
    var body = jsonDecode(res.body);
    var data = body['data'];
    var relations = body['relationships'];
    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'],
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }
    // ignore: omit_local_variable_types
    Map<String, dynamic> chapters = {};
    // append available chapters from other API endpoint
    if (appendChapters) {
      var chres = await http.get(
          Uri.parse('https://api.mangadex.org/manga/$uuid/aggregate'),
          headers: {HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'});
      chapters = Map.from(jsonDecode(chres.body)['volumes']);
    }
    var cover, author, artist;
    for (var rel in relations) {
      switch (rel['type']) {
        case 'author':
          author = Author(
              name: rel['attributes']['name'],
              id: rel['id'],
              biography: rel['attributes']['biography'],
              imageUrl: rel['attributes']['imageUrl']);
          break;
        case 'artist':
          artist = Author(
              name: rel['attributes']['name'],
              id: rel['id'],
              imageUrl: rel['attributes']['imageUrl'],
              biography: rel['attributes']['biography']);
          break;
        case 'cover_art':
          cover =
              'https://uploads.mangadex.org/covers/$uuid/${rel['attributes']['fileName']}';
          break;
        default:
          break;
      }
    }
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
      author: author,
      artist: artist,
      cover: cover,
    );
    return manga;
  }

  /// Gets `10` of available cover images for a manga
  ///
  /// Requires valid manga UUID
  ///
  /// Returns [Null] if no found
  Future<List<String>?> getCovers(String mangaUuid,
      {bool useLogin = false}) async {
    var res;
    if (token != '' && useLogin) {
      res = await http.get(
          Uri.parse('https://api.mangadex.org/cover?manga[]=$mangaUuid'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
            HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
          });
    } else {
      res = await http.get(
          Uri.parse('https://api.mangadex.org/cover?manga[]=$mangaUuid'),
          headers: {HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'});
    }
    if (res.statusCode == 404) {
      return null;
    }
    var data = jsonDecode(res.body)['results'];
    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'],
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }
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
  ///
  /// **`status` MUST BE ONE OF `["ongoing","completed","hiatus","cancelled"]`**
  ///
  /// For more info see [the official documentation](https://api.mangadex.org/docs.html#operation/get-search-manga)
  ///
  /// Returns an empty [List<String>] if no results
  Future<List<Manga>> search(
      {String mangaTitle = '',
      List<String> authors = const [],
      List<String> includedTags = const [],
      List<String> excludedTags = const [],
      List<String> status = const [],
      List<String> demographic = const [],
      bool useLogin = false}) async {
    var res;
    if (token != '' && useLogin) {
      res = await http.get(
          Uri.parse(
              'https://api.mangadex.org/manga?title=&includes[]=author&includes[]=artist&includes[]=cover_art$mangaTitle${(authors.isNotEmpty) ? '&authors[]=${authors.join('&authors[]=')}' : ''}${(includedTags.isNotEmpty) ? '&includedTags[]=${includedTags.join('&includedTags[]=')}' : ''}${(excludedTags.isNotEmpty) ? '&excludedTags[]=${excludedTags.join('&excludedTags[]=')}' : ''}${(status.isNotEmpty) ? '&status[]=${status.join('&status[]=')}' : ''}${(demographic.isNotEmpty) ? '&publicationDemographic[]=${demographic.join('&publicationDemographic[]=')}' : ''}'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
            HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
          });
    } else {
      res = await http.get(
          Uri.parse(
              'https://api.mangadex.org/manga?title=$mangaTitle&includes[]=author&includes[]=artist&includes[]=cover_art${(authors.isNotEmpty) ? '&authors[]=${authors.join('&authors[]=')}' : ''}${(includedTags.isNotEmpty) ? '&includedTags[]=${includedTags.join('&includedTags[]=')}' : ''}${(excludedTags.isNotEmpty) ? '&excludedTags[]=${excludedTags.join('&excludedTags[]=')}' : ''}${(status.isNotEmpty) ? '&status[]=${status.join('&status[]=')}' : ''}${(demographic.isNotEmpty) ? '&publicationDemographic[]=${demographic.join('&publicationDemographic[]=')}' : ''}'),
          headers: {HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'});
    }
    var data = jsonDecode(res.body);
    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'],
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }

    if (res.statusCode == 400) {
      throw 'Error: ${data["errors"][0]["title"]} - ${data["errors"][0]["detail"]}';
    }

    List<Manga>? results = [];
    for (var manga in data['results']) {
      var r = manga['data'];
      var relations = manga['relationships'];
      var cover, author, artist;
      for (var rel in relations) {
        switch (rel['type']) {
          case 'author':
            author = Author(
                name: rel['attributes']['name'],
                id: rel['id'],
                biography: rel['attributes']['biography'],
                imageUrl: rel['attributes']['imageUrl']);
            break;
          case 'artist':
            artist = Author(
                name: rel['attributes']['name'],
                id: rel['id'],
                imageUrl: rel['attributes']['imageUrl'],
                biography: rel['attributes']['biography']);
            break;
          case 'cover_art':
            cover =
                'https://uploads.mangadex.org/covers/${r['id']}/${rel['attributes']['fileName']}';
            break;
          default:
            break;
        }
      }
      results.add(
        Manga(
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
            id: r['id'],
            cover: cover,
            author: author,
            artist: artist),
      );
    }
    return results;
  }

  /// Gets user
  ///
  /// Requires user's `uuid`
  ///
  /// Returns [Null] if not found
  Future<User?> getUser(String uuid, {bool useLogin = false}) async {
    var res;
    if (token != '' && useLogin) {
      res = await http
          .get(Uri.parse('https://api.mangadex.org/user/$uuid'), headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
      });
    } else {
      res = await http.get(Uri.parse('https://api.mangadex.org/user/$uuid'),
          headers: {HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'});
    }
    var data = jsonDecode(res.body)['data'];

    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'].toString(),
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }
    if (res.statusCode == 404) {
      return null;
    }
    var user = User(id: data['id'], username: data['attributes']['username']);
    return user;
  }

  /// Gets information about a Scanlation Group
  ///
  /// Requires group's `uuid`
  ///
  /// Returns [Null] if no results
  Future<Group?> getGroup(String uuid, {bool useLogin = false}) async {
    var res;
    if (token != '' && useLogin) {
      res = await http.get(
          Uri.parse(
              'https://api.mangadex.org/group/$uuid?includes[]=leader&includes[]=member'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
            HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
          });
    } else {
      res = await http.get(
          Uri.parse(
              'https://api.mangadex.org/group/$uuid?includes[]=leader&includes[]=member'),
          headers: {HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'});
    }
    var body = jsonDecode(res.body);
    var data = body['data'];
    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'].toString(),
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }
    if (res.statusCode == 404) {
      return null;
    }

    var members = <User>[];
    var leader;
    for (var member in body['relationships']) {
      if (member['type'] == 'member') {
        members.add(
            User(id: member['id'], username: member['attributes']['username']));
      } else if (member['type'] == 'leader') {
        leader =
            User(id: member['id'], username: member['attributes']['username']);
      }
    }

    var group = Group(
        id: data['id'],
        name: data['attributes']['name'],
        isLocked: data['attributes']['locked'],
        createdAt: data['attributes']['createdAt'],
        updatedAt: data['attributes']['updatedAt'],
        description: data['attributes']['description'],
        website: data['attributes']['website'],
        ircChannel: data['attributes']['ircChannel'],
        ircServer: data['attributes']['ircServer'],
        discord: data['attributes']['discord'],
        contactEmail: data['attributes']['contactEmail'],
        leader: leader);
    return group;
  }

  /// Searches for groups with the given parameters
  ///
  /// Returns an empty [List] if no results
  Future<List<Group>> searchGroups(
      {bool useLogin = false,
      String name = '',
      List<String> ids = const []}) async {
    var res;
    if (token != '' && useLogin) {
      res = await http.get(
          Uri.parse(
              'https://api.mangadex.org/group?name=$name&includes[]=leader&includes[]=member${(ids.isNotEmpty) ? '&ids[]=${ids.join('&ids[]=')}' : ''}'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
            HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
          });
    } else {
      res = await http.get(
          Uri.parse(
              'https://api.mangadex.org/group?name=$name&includes[]=leader&includes[]=member${(ids.isNotEmpty) ? '&ids[]=${ids.join('&ids[]=')}' : ''}'),
          headers: {HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'});
    }
    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'].toString(),
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }
    var data = jsonDecode(res.body)['results'];
    // ignore: omit_local_variable_types
    List<Group> groups = [];

    for (var group in data) {
      var r = group['data'];

      var members = <User>[];
      var leader;
      for (var member in group['relationships']) {
        if (member['type'] == 'member') {
          members.add(User(
              id: member['id'], username: member['attributes']['username']));
        } else if (member['type'] == 'leader') {
          leader = User(
              id: member['id'], username: member['attributes']['username']);
        }
      }
      groups.add(Group(
          id: r['id'],
          name: r['attributes']['name'],
          isLocked: r['attributes']['locked'],
          createdAt: r['attributes']['createdAt'],
          updatedAt: r['attributes']['updatedAt'],
          description: r['attributes']['description'],
          website: r['attributes']['website'],
          ircChannel: r['attributes']['ircChannel'],
          ircServer: r['attributes']['ircServer'],
          discord: r['attributes']['discord'],
          contactEmail: r['attributes']['contactEmail'],
          leader: leader,
          members: members));
    }

    return groups;
  }

  /// Invalidates current sesssion
  Future<void> logout() async {
    if (token == '') return;
    var res = await http
        .post(Uri.parse('https://api.mangadex.org/auth/logout'), headers: {
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
    });
    var data = jsonDecode(res.body);
    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'].toString(),
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }
    if (res.statusCode != 200) {
      throw 'An error has happened: ${data["errors"][0]["title"]} - ${data["errors"][0]["detail"]}';
    }
    token = '';
    refresh = '';
  }

  /// Returns the latest chapters of the currently logged in user's followed manga
  ///
  /// If you did not login, this will return an empty [List]
  Future<List<Chapter>> getMangaFeed() async {
    // ignore: omit_local_variable_types
    List<Chapter> chapters = [];
    if (token == '') return chapters;
    var res = await http.get(
        Uri.parse('https://api.mangadex.org/user/follows/manga/feed'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
        });
    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'].toString(),
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }
    var data = jsonDecode(res.body)['results'];
    for (var chapter in data) {
      var r = chapter['data'];

      var getme = await generateChapter(r);
      var normalChapter = getme['normal']!;
      var saverChapter = getme['saver']!;

      chapters.add(Chapter(
          chapterURLs: normalChapter,
          dataSaverChapterURLs: saverChapter,
          id: r['id'],
          title: r['attributes']['title'],
          translatedLanguage: r['attributes']['translatedLanguage'],
          volumeNum: r['attributes']['volume'],
          chapterNum: r['attributes']['chapter'],
          createdAt: r['attributes']['createdAt'],
          updatedAt: r['attributes']['updatedAt'],
          uploader: r['attributes']['uploaded']));
    }
    return chapters;
  }

  /// Gets logged in user's CustomLists
  ///
  /// Returns an empty [List] if no user is logged in
  Future<List<GenericObject>> getUsersLists() async {
    if (token == '') return <GenericObject>[];
    var res = await http
        .get(Uri.parse('https://api.mangadex.org/user/list'), headers: {
      HttpHeaders.authorizationHeader: 'Bearer: $token',
      HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0'
    });
    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'].toString(),
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }
    var data = jsonDecode(res.body)['results'];
    var objects = <GenericObject>[];
    for (var result in data) {
      objects.add(GenericObject(
          id: result['id'],
          type: result['type'],
          title: result['attributes']['name']));
    }
    return objects;
  }

  /// Gets a CustomList chapter feed
  ///
  /// Returns an empty list if
  /// a) CustomList was not found or you don't have access to it.
  /// b) You're not logged in
  Future<List<Chapter>> getListFeed(id) async {
    if (token == '' || id == '') return <Chapter>[];
    var res = await http
        .get(Uri.parse('https://api.mangadex.org/list/$id/feed'), headers: {
      HttpHeaders.userAgentHeader: 'mangadex_dart_api/1.0',
      HttpHeaders.authorizationHeader: 'Bearer: $token'
    });
    if (res.statusCode == 403 && res.headers['X-Captcha-Sitekey'] != null) {
      throw CaptchaException(res.headers['X-Captcha-Sitekey'].toString(),
          message:
              'You need to solve a captcha, check `.sitekey` for the sitekey.');
    }
    var data = jsonDecode(res.body)['results'];
    var chapters = <Chapter>[];
    for (var chap in data) {
      var r = chap['data'];
      var getme = await generateChapter(r);
      var normalChapter = getme['normal']!;
      var saverChapter = getme['saver']!;

      chapters.add(Chapter(
          chapterURLs: normalChapter,
          dataSaverChapterURLs: saverChapter,
          id: r['id'],
          title: r['attributes']['title'],
          translatedLanguage: r['attributes']['translatedLanguage'],
          volumeNum: r['attributes']['volume'],
          chapterNum: r['attributes']['chapter'],
          createdAt: r['attributes']['createdAt'],
          updatedAt: r['attributes']['updatedAt'],
          uploader: r['attributes']['uploaded']));
    }
    return chapters;
  }
}
