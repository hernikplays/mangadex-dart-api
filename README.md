A MangaDex API wrapper for Dart

## Usage

A simple usage example:

```dart
import 'package:mangadex_api/mangadex_api.dart';

main() {
  var client = MDClient();

  client.getChapter('5e8bc984-5f3f-4fb1-b6ee-cf7f3812b112').then((chapter) {
    print(chapter!.title);
  });

  client.getMangaInfo('a96676e5-8ae2-425e-b549-7f15dd34a6d8',
      appendChapters: true, translatedLang: ['cs']).then((m) {
    print(m!.title['en']);
  });
}
```
## What's implemented
- Log-in
- Get Chapters
- Get Manga

## What's NOT yet implemented
- Get cover
- Captcha
- Get user
- Get group
- Search

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hernikplays/mangadex-dart-api/issues
