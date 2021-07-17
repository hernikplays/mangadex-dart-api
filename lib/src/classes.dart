/// Holds data about a single Chapter
class Chapter {
  /// Chapter ID
  final String id;

  /// Title of the chapter
  final String title;

  /// Volume number, is [Null] if not specified in API
  final String? volume;

  /// Chapter number, is [Null] if not specified in API
  final String? chapter;

  /// Language of the chapter
  final String translatedLanguage;

  /// URLs for individual pages
  final List<String> chapterURLs;

  /// URLs for pages with data-saver enabled
  final List<String> dataSaverChapterURLs;

  /// The uploader of the chapter
  final String? uploader;

  /// IDs of groups credited in the chapter
  final List<String>? groupIds;

  /// ID of the parent manga
  final String? mangaId;

  /// Date when the chapter was created
  final String createdAt;

  /// Date of last chapter update
  final String updatedAt;

  Chapter(
      {required this.dataSaverChapterURLs,
      this.uploader,
      this.groupIds,
      this.mangaId,
      required this.createdAt,
      required this.updatedAt,
      required this.id,
      required this.title,
      required this.translatedLanguage,
      required this.chapterURLs,
      this.volume,
      this.chapter});
}

/// Holds data about a Manga
class Manga {
  /// Manga ID
  final String id;

  /// Original title of manga
  final Map<String, dynamic> title;

  /// Alternative manga titles (with other languages)
  final List<dynamic> altTitles;

  /// Full manga description
  final Map<String, dynamic> description;

  /// Manga locked status
  final bool? isLocked;

  /// Links to author etc.
  final Map<String, dynamic>? links;

  /// Original language of the manga
  final String originalLang;

  /// Last volume
  final String? lastVolume;

  /// Last chapter
  final String? lastChapter;

  /// Target demographic
  final String? demographic;

  /// Publishing status
  final String? status;

  /// Year of release
  final String? releaseYear;

  /// Content rating
  final String? contentRating;

  /// Manga tags
  final List<dynamic> tags;

  /// Date when the chapter was created
  final String createdAt;

  /// Date of last chapter update
  final String updatedAt;

  /// available chapters from the /aggregate endpoint
  final Map<String, dynamic>? chapters;

  /// list of URLs for cover images (same as from the [getCovers] function)
  final List<String>? covers;

  Manga(
      {required this.id,
      required this.title,
      required this.altTitles,
      required this.description,
      required this.isLocked,
      required this.originalLang,
      required this.tags,
      required this.createdAt,
      required this.updatedAt,
      this.demographic,
      this.lastChapter,
      this.lastVolume,
      this.contentRating,
      this.links,
      this.releaseYear,
      this.status,
      this.chapters,
      this.covers});
}

/// Holds data about a MangaDex user
class User {
  /// User's username
  final String username;

  /// User's ID
  final String id;
  User({required this.username, required this.id});
}

/// Exception thrown when the API server returns a 403 error requiring completion of a captcha
///
/// For more info on MangaDex API's captchas check [this part of their API](https://api.mangadex.org/docs.html#section/Captchas)
///
/// For sending the captcha result use the solveCaptcha function
class CaptchaException implements Exception {
  /// Additional message
  final String message;

  /// Recaptcha site key used for rendering the [widget](https://developers.google.com/recaptcha/docs/display#auto_render)
  final String sitekey;
  CaptchaException(this.sitekey, {this.message = ''});
}
