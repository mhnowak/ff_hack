## Google Photos shared album → BadgeScreen (Flutter) 

### Overview
Fetch images from a Google Photos shared album via the Photos Library API, cache/download them, and render as circular badges in `BadgeScreen`.

### Step 1 — Google Cloud setup
- **Create project** in Google Cloud Console.
- **Enable** “Google Photos Library API”.
- **Configure OAuth consent** (External), add scopes and test users.
- **Create OAuth client IDs**:
  - Android client: set package name and SHA-1.
  - iOS client: set bundle identifier.

### Step 2 — Add Flutter dependencies
Add to `pubspec.yaml`:
- `google_sign_in`
- `googleapis` (Photos Library)
- `http` (or `dio`)
- `cached_network_image` (optional)
- `path_provider` + `flutter_cache_manager` (optional for manual caching)

### Step 3 — Platform configuration
- **Android**: ensure minSdk ≥ 21; configure package name and SHA-1 in the Android OAuth client.
- **iOS**: add URL scheme with iOS OAuth `REVERSED_CLIENT_ID` to `ios/Runner/Info.plist`.

### Step 4 — Decide how to access the shared album
- If you already joined the album in Google Photos: use `sharedAlbums.list` and pick it.
- If you only have a share link: extract the share token and `sharedAlbums.join` to get an `albumId`.

### Step 5 — Scopes (required)
- `https://www.googleapis.com/auth/photoslibrary.readonly`
- `https://www.googleapis.com/auth/photoslibrary.sharing`
- Optional basic identity: `email`

### Step 6 — Sign in and get auth headers
```dart
final googleSignIn = GoogleSignIn(scopes: [
  'email',
  'https://www.googleapis.com/auth/photoslibrary.readonly',
  'https://www.googleapis.com/auth/photoslibrary.sharing',
]);
final account = await googleSignIn.signIn();
final authHeaders = await account?.authHeaders; // Bearer token in headers
```

### Step 7 — Create Photos Library API client
```dart
import 'package:googleapis/photoslibrary/v1.dart' as photos;
import 'package:http/http.dart' as http;

class _AuthClient extends http.BaseClient {
  _AuthClient(this._headers);
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

final client = _AuthClient(authHeaders!);
final photosApi = photos.PhotosLibraryApi(client);
```

### Step 8 — Obtain the albumId
- Join by token:
```dart
final joined = await photosApi.sharedAlbums.join(
  photos.JoinSharedAlbumRequest()..shareToken = '<SHARE_TOKEN>',
);
final albumId = joined.sharedAlbum?.id;
```
- Or list shared albums:
```dart
final shared = await photosApi.sharedAlbums.list(pageSize: 50);
final album = shared.sharedAlbums?.firstWhere((a) => a.title == 'Your Album Name');
final albumId = album?.id;
```

### Step 9 — List media items with pagination
```dart
String? pageToken;
final List<photos.MediaItem> allItems = [];

do {
  final res = await photosApi.mediaItems.search(
    photos.SearchMediaItemsRequest()
      ..albumId = albumId
      ..pageSize = 100
      ..pageToken = pageToken,
  );
  allItems.addAll(res.mediaItems ?? []);
  pageToken = res.nextPageToken;
} while (pageToken != null);
```

### Step 10 — Map to a Badge model
```dart
class Badge {
  final String id;
  final String imageUrl;
  final String? label;
  Badge({required this.id, required this.imageUrl, this.label});
}

List<Badge> toBadges(List<photos.MediaItem> items) => items.map((m) {
  final url = '${m.baseUrl}=w512-h512-c'; // square crop thumbnail
  return Badge(id: m.id!, imageUrl: url, label: m.filename);
}).toList();
```

### Step 11 — Render in BadgeScreen
```dart
GridView.builder(
  padding: const EdgeInsets.all(16),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
  ),
  itemCount: badges.length,
  itemBuilder: (_, i) {
    final b = badges[i];
    return ClipOval(
      child: Image.network(b.imageUrl, fit: BoxFit.cover),
    );
  },
);
```

### Step 12 — Caching / downloads
- Quick path: use `CachedNetworkImage` with `imageUrl: '${item.baseUrl}=w1024'`.
- To download bytes: `GET '${item.baseUrl}=d'` with auth headers; store in temp/cache dir.

### Step 13 — Handle edge cases
- Pagination (done above), offline handling, 401 re-auth, 429/5xx backoff.
- iOS keychain and Android token storage are handled by `google_sign_in`.

### Minimal checklist
- Enable API + configure OAuth clients (Android/iOS) and consent screen.
- Add deps; configure iOS URL scheme.
- Sign in with required scopes.
- Join/find shared album → get `albumId`.
- Fetch `mediaItems` (paginate).
- Map to `Badge` model.
- Render grid of circular thumbnails with caching/loading UI.

### References
- Google Photos Library REST: `https://developers.google.com/photos/library/reference/rest`
- Dart package: `https://pub.dev/packages/googleapis`


