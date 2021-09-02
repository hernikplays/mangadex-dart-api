## 1.0.1
- Add `translatedLanguage` to `getMangaFeed`
- Add reference expansion to `followedManga` and `followedGroups`
- Add `createCustomList`, `deleteCustomList`, `addToCustomList` and `removeFromCustomList`

For more changes check out the [GitHub diff](https://github.com/hernikplays/mangadex-dart-api/compare/d4edb8eb8e40e5b0f0a16cc53031728d988fb3c7..44e5bd1601116fdf38292db6dc9cdf2e1f9ab75a) and the [documentation][doc]

## 1.0.0
- Manga class - cover is now nullable
- Every function should throw exception in case of a 4xx or 5xx error
- Better `getChapter` method, thanks to [#2](https://github.com/hernikplays/mangadex-dart-api/pull/2)
- Functions now validate token using the `validateToken` function
- Added `getUsersList` function
- Added `getListFeed` function
- Added `loggedInUser` function
- Added `followedManga` function
- Added `followedGroups` function


For more changes check out the [GitHub diff](https://github.com/hernikplays/mangadex-dart-api/compare/1.0.0-dev2...1.0.0) and the [documentation][doc]
## 1.0.0-dev.2
- Added User class and getUser function
- Added checking for captcha on request
- added solveCaptcha function
- added Group class and getGroup function
- all requests will **no longer** be automatically sent with your token, if you logged in, you need to set `useLogin` to `true` in the respective function
- added the `mangadex-dart-api/1.0` header to all requests to the API
- **renamed `getMangaInfo` to `getManga`**
- added reference expansion to `getManga` and `search`
- login now **returns a Future**
- **changed in Chapter class: `chapter -> chapterNum` & `volume -> volumeNum`**

For more changes check out the [documentation][doc]

## 1.0.0-dev.1

- Initial version.

[doc]: https://pub.dev/documentation/mangadex_api/latest/
