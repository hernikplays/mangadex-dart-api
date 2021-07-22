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

For more changes check out the [documentation](https://hernikplays.cz/mangadex-dart-api/1.0.0-dev.2/mangadex_api/mangadex_api-library.html)

## 1.0.0-dev.1

- Initial version.
