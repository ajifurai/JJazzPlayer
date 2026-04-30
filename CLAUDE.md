# JJaZZPlayer

JJazz.Net番組をiOSネイティブで再生するアプリ。個人利用。pick-upと夜ジャズ.Netの2番組対応。

## 技術スタック

- Xcode 26 / Swift 6.3 (`SWIFT_STRICT_CONCURRENCY=minimal`)
- SwiftUI + AVFoundation + MediaPlayer + Combine
- XcodeGen 2.45.4 (`project.yml`)
- iOS 17.0 minimum deployment target

## ディレクトリ構成

```
JJaZZPlayer/
├── project.yml
├── Sources/
│   ├── JJaZZPlayerApp.swift           — TabView (pick-up / 夜ジャズ)
│   ├── Models/
│   │   ├── Program.swift              — ShowType enum, displayTitle stored
│   │   └── Track.swift
│   ├── Services/
│   │   ├── JJazzScraper.swift         — HTML scrape + regex抽出
│   │   └── AudioPlayerService.swift  — @MainActor singleton
│   ├── ViewModels/
│   │   └── ProgramListViewModel.swift — ShowType別フェッチ
│   └── Views/
│       ├── ProgramListView.swift      — showType引数、TabView各タブ
│       ├── ProgramDetailView.swift    — トラック一覧、safeAreaInset
│       ├── ProgramRowView.swift
│       ├── TrackRowView.swift
│       └── PlayerControlsView.swift  — 再生コントロール + AirPlay
└── Tests/
    ├── JJazzScraperTests.swift        (7テスト)
    ├── PlaylistParserTests.swift      (8テスト)
    └── ProgramTests.swift             (3テスト)
```

## モデル

```swift
enum ShowType: String, Codable { case pickup = "pick-up"; case yorujazz }

struct Program: Identifiable, Codable {
    let id: String          // "J-1955" 形式
    let showType: ShowType
    let displayTitle: String  // スクレイパー側で生成・格納
    var savedPosition: Double
    var tracks: [Track]
    var audioURL: URL        // https://jjazz-aod.leanstream.co:8001/jjazz/{id}.mp3
}
```

## スクレイピング

### pick-up
- 最新: `https://www.jjazz.net/programs/pick-up/`
- 過去: `https://www.jjazz.net/programs/pick-up/{yy}{month}.php` (例: `26april.php`)
- prog番号抽出: `jjazzplayer\('(J-\d+)'`
- タイトル生成: `"\(year)年\(month)月 pick-up"`

### 夜ジャズ
- 一覧: `https://www.jjazz.net/programs/yorujazz/`
- エピソード抽出パターン: `href="(https://www\.jjazz\.net/programs/yorujazz/[^"]+\.php)" title="([^"]+)"`
- タイトル例: `"夜ジャズ.Net#211 - akiko"`
- ソート: タイトルの `#(\d+)` でエピソード番号降順

## AudioPlayerService 重要実装メモ

### Swift 6.3 actor isolation クラッシュ対策

`MPMediaItemArtwork` の `requestHandler` クロージャはMediaPlayerが**バックグラウンドスレッド**(`accessQueue`)から呼ぶ。
`@MainActor` メソッド内で定義するとクロージャが `@MainActor` 隔離を継承し、Swift 6.3の実行時チェック(`dispatch_assert_queue`)でクラッシュ。

対策: artwork生成は `nonisolated func` に分離してクロージャ隔離を外す。

```swift
@MainActor
private func setArtworkFromData(_ data: Data) {
    guard let artwork = makeArtwork(from: data) else { return }
    var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
    info[MPMediaItemPropertyArtwork] = artwork
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
}

private nonisolated func makeArtwork(from data: Data) -> MPMediaItemArtwork? {
    guard let img = UIImage(data: data), let cgImage = img.cgImage else { return nil }
    let size = img.size
    let uiImage = UIImage(cgImage: cgImage, scale: img.scale, orientation: .up)
    return MPMediaItemArtwork(boundsSize: size) { _ in uiImage }
}
```

## リモートコマンド

- 再生/一時停止: `playCommand` / `pauseCommand` / `togglePlayPauseCommand`
- スキップ: `skipForwardCommand` (+30秒) / `skipBackwardCommand` (-15秒)
- トラック移動: `nextTrackCommand` / `previousTrackCommand`
  - 前の曲: 現在位置 - 曲開始 > 3秒なら頭出し、以内なら前曲へ

## UI構成

- `TabView`: pick-upタブ + 夜ジャズタブ
- `List` に `.safeAreaInset(edge: .bottom)` で `PlayerControlsView` を表示（NavigationStackレベルでは届かない）
- `PlayerControlsView`: アルバムアート + タイトル/アーティスト + スライダー + 再生ボタン + `AVRoutePickerView`(AirPlay)
- 再生位置はアプリバックグラウンド時に `UserDefaults` 保存 (`"pos_{id}"`)

## デバッグ機種

- しんフォン (iPhone 13 mini): `D64189DA-7007-5146-AF37-1C2BE59AD9C2`
- Shin mini gen6 (iPad mini 6): `DEC97931-AA04-55F5-B536-ABF328452C5C`

## ビルド・インストール

```bash
xcodebuild -project JJaZZPlayer.xcodeproj -scheme JJaZZPlayer \
  -destination "id=D64189DA-7007-5146-AF37-1C2BE59AD9C2" build

xcrun devicectl device install app \
  --device D64189DA-7007-5146-AF37-1C2BE59AD9C2 \
  /path/to/DerivedData/.../Debug-iphoneos/JJaZZPlayer.app
```
