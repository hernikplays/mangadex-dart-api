A MangaDex API wrapper for Dart

[![Open in Visual Studio Code](https://open.vscode.dev/badges/open-in-vscode.svg)](https://open.vscode.dev/hernikplays/mangadex-dart-api) [![Dart Test](https://github.com/hernikplays/mangadex-dart-api/actions/workflows/dart.yml/badge.svg)](https://github.com/hernikplays/mangadex-dart-api/actions/workflows/dart.yml)

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

Currently if you login, only requests __where authentication is required__ will be done with your token, **unless** you set the `useLogin` parameter in a function as true.

## Captcha
If the server returns a captcha, the library will throw a [CaptchaException], which, if handled, has the sitekey inside. After you solve the captcha, you need to pass the result to the [solveCaptcha] function.

## What's implemented
- Log-in
- Getting Chapters
- Getting Manga
- Getting cover
- Manga search
- Getting user
- Captcha
- Getting group
- Logged in user's followed manga chapter feed
- Getting CustomList
- Getting CustomList's chapter feed
- Getting followed manga & group list


## What's NOT yet implemented
- Managing actions (Following, changing reading status etc.)
- Creating accounts
- And other stuff...

**Don't forget to check the [docs](https://pub.dev/documentation/mangadex_api/latest/)**

## Features and bugs

**Please file feature requests and bugs at the [issue tracker][tracker].**

[tracker]: https://github.com/hernikplays/mangadex-dart-api/issues
