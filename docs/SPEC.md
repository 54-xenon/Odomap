# Odomap 仕様書

## 1. 概要

Odomap（オドマップ）は、バイク／自転車ツーリングの走行記録を GPS で自動計測する iOS アプリ。走行中の距離・速度・獲得標高・天気をリアルタイムに表示し、走行終了後はルート地図付きのサマリーとして保存・閲覧できる。

- プラットフォーム: iOS（SwiftUI, iOS 26 系 API — `glassEffect` 使用）
- 永続化: SwiftData（ローカルのみ、CloudKit 同期なし）
- 位置情報: Core Location（バックグラウンド追跡対応）
- 高度計測: Core Motion（気圧高度計、GPS高度のフォールバックあり）
- 天気: WeatherKit
- 通知: UserNotifications（ローカル通知のみ、リモート通知なし）
- 対応言語: 日本語（UI文言・日付フォーマットは `ja_JP` 固定）
- 対応向き: iPhone は縦固定、iPad は横固定（Landscape Left/Right）

## 2. アーキテクチャ

```
Odomap/
├── OdomapApp.swift        # エントリポイント、SwiftData ModelContainer 設定
├── Models/
│   └── Ride.swift         # Ride（走行記録）モデル、ルート正規化ロジック
├── Screens/
│   ├── ContentView.swift      # ルートのタブ構成（Home / History / Settings）
│   ├── HomeView.swift         # ホーム画面（記録開始ボタン）
│   ├── RecordView.swift       # 記録中画面 + RecordingSession
│   ├── RideSummaryView.swift  # 記録終了直後 / 履歴詳細の共用サマリー画面
│   ├── HistoryView.swift      # 記録一覧
│   └── SettingView.swift      # 設定画面
├── Services/
│   ├── LocationManager.swift     # GPS計測・距離/速度/獲得標高の算出
│   ├── WeatherManager.swift      # WeatherKit連携・熱中症警告トリガー
│   ├── SettingsStore.swift       # UserDefaults ベースの設定永続化
│   └── NotificationManager.swift # ローカル通知の送信・フォアグラウンド表示
└── UI/
    ├── Theme.swift         # カラーパレット、背景グラデーション、ブランドマーク、時間フォーマット
    └── RouteVisuals.swift  # ルートサムネイル・ルートマップ描画コンポーネント
```

状態管理は Swift `Observation`（`@Observable`）を使用。`LocationManager` / `WeatherManager` / `RecordingSession` は各画面の `@State` として保持される。設定は `SettingsStore.shared` のシングルトンで全画面から参照する。

## 3. データモデル

### 3.1 `Ride`（SwiftData `@Model`）

| プロパティ | 型 | 説明 |
|---|---|---|
| `id` | `UUID` | 一意識別子 |
| `name` | `String` | 記録名（現状は固定文字列「今日のツーリング」で自動生成、編集UIは未実装） |
| `date` | `Date` | 記録開始日時 |
| `distanceKm` | `Double` | 総走行距離（km） |
| `duration` | `TimeInterval` | 走行時間（秒） |
| `maxSpeedKmh` | `Double` | 最高速度（km/h） |
| `elevationGain` | `Double` | 獲得標高（m） |
| `storedCoordinates`（private） | `[StoredCoordinate]` | 走行軌跡（緯度経度の配列） |
| `thumbnailColorHexValues`（private） | `[Int]` | サムネイル用グラデーション色（16進） |

導出プロパティ:
- `coordinates`: `storedCoordinates` を `CLLocationCoordinate2D` に変換
- `route`: `RouteData.fromCoordinates(coordinates)` — GPS座標をバウンディングボックスで 0〜1 に正規化した折れ線データ（サムネイル描画用）
- `avgSpeedKmh`: `distanceKm / (duration / 3600)`
- `distanceText` / `avgSpeedText` / `maxSpeedText`: `SettingsStore` の単位設定に応じてフォーマット
- `elevationText`: `"%.0f m"`
- `shortDateText`("M/d") / `listDateText`("M月d日") / `fullDateText`("M月d日（E）")

`StoredCoordinate` は `CLLocationCoordinate2D` が `Codable` 非準拠のための永続化用ラッパー（緯度・経度のみ保持）。

### 3.2 `RouteData` / `RouteCurve`

サムネイル・軽量描画用に、実座標を 0〜1 のベジェ曲線データへ変換する構造体。あらかじめ用意されたプリセット（`diagonal` / `coastal` / `winding`、未使用のサンプル形状）と、実GPS座標から生成する `fromCoordinates(_:)` がある。実データは各点を制御点=終点とした折れ線として扱われる。

## 4. 画面仕様

### 4.1 タブ構成（`ContentView`）

`TabView` に 3 タブ:

1. **Home**（house アイコン）
2. **History**（chart.bar アイコン）
3. **Settings**（gearshape アイコン）

`Home` の記録開始ボタン押下で `isRecording = true` となり、`RecordView` を `fullScreenCover` として表示する。記録終了時、`RecordView` から渡された `Ride` を `modelContext.insert(ride)` でSwiftDataに保存する。

### 4.2 Home（`HomeView`）

- 背景: `SkyGradientBackground`（上部がうっすら青いグラデーション）
- タイトル「Odomap」
- 中央の円形「記録開始」ボタン
  - バイクのラインアートアイコン（`BikeMark`）+ 「記録開始」ラベル
  - 直径 186pt の円、青系グラデーション塗り（ライト/ダークで配色が異なる）
  - タップで記録画面（`RecordView`）をフルスクリーン表示

### 4.3 記録中（`RecordView`）

記録セッション（`RecordingSession`）は開始時刻・一時停止状態・経過時間の計算を担当する。一時停止中は経過時間が加算されない。

**画面構成:**
- 背景: `SkyGradientBackground(strong: true)`
- ヘッダー: 開始時刻（例: "14:32 開始"）
- 中央: 走行時間の大表示（`TimelineView` で毎秒更新、`HH:MM:SS` 形式）
- 2×2 グリッドのメトリクスカード（`glassEffect` によるグラス調カード）:
  - 距離（設定単位に応じ km/mi）
  - 現在速度（km/h または mph）
  - 天気（アイコン + 気温、WeatherKitから取得）
  - 高度（m、気圧高度計 or GPS高度）
- フッター: 「一時停止／再開」ボタンと「終了」ボタン（赤系グラス調カプセル）

**位置情報許可フロー（`attemptStart()`）:**
- `notDetermined` → 使用中のみ許可をリクエスト
- `authorizedWhenInUse` → 常に許可への昇格をリクエストしつつ記録開始
- `authorizedAlways` → そのまま記録開始
- `denied` / `restricted` → アラート表示し、「設定を開く」で設定アプリへ誘導

**天気の更新開始:** 最初のGPS座標が得られたタイミングで `WeatherManager.start(coordinateProvider:)` を一度だけ呼び出す。

**終了処理（`finishRecording()`）:** 位置情報の記録を停止し、収集した座標・距離・時間・最高速度・獲得標高から `Ride` を生成して `finishedRide` にセット。これにより画面が `RideSummaryView`（保存ボタン付き）に切り替わる。保存確定時のみ `onSave` コールバック経由で `ContentView` に伝わり、SwiftDataへ永続化される。

### 4.4 記録終了 / 詳細（`RideSummaryView`）

`onSave` クロージャの有無で2つのモードを兼ねる:
- **記録直後モード**（`onSave != nil`）: ヘッダー（記録名・日付・保存ボタン）を表示。「保存」タップで `onSave()` → 呼び出し元が保存 → `dismiss()`。
- **履歴詳細モード**（`onSave == nil`, `HistoryView` からの `NavigationLink` 遷移）: ヘッダーなし、`navigationTitle` に記録名を表示。

**共通コンテンツ:**
- `RouteMapCard`: 実座標を `MapPolyline` で描画した `MapKit` の地図（開始地点=緑マーカー、終了地点=赤マーカー）。座標が無い場合は東京駅周辺をデフォルト表示。
- 2×2 統計グリッド: 総距離・走行時間・平均速度・最高速度
- 獲得標高（1行の横長カード）

### 4.5 記録一覧（`HistoryView`）

- `Ride.date` の降順で一覧表示（SwiftData `@Query`）
- 記録が0件の場合、`ContentUnavailableView` で空状態を表示（「記録がありません」）
- 各行: `RouteThumbnail`（56×56、ルート曲線+開始/終了ドット） / 記録名 / 日付 / 距離 / 走行時間
- 行タップで `RideSummaryView`（詳細モード）へ遷移
- ナビゲーションタイトル「記録一覧」

### 4.6 設定（`SettingView`）

`SettingsStore.shared` を `@Bindable` で参照する `List` ベースの設定画面。

| セクション | 項目 | 選択肢 / 型 |
|---|---|---|
| 単位 | 距離・速度の単位 | km / mi |
| 計測 | 精度優先モード | ナビ用（高精度） / バランス（省電力） |
| 計測 | 気圧高度計を使用 | Toggle（デフォルト ON） |
| 計測 | 天気の更新間隔 | 5分 / 10分 / 15分 / 30分 |
| 通知・連携 | 通知 | Toggle（ONにした時のみ通知許可をリクエストし、許可された場合だけ有効化） |
| （無題） | バージョン | `CFBundleShortVersionString`（読み取り専用表示） |

## 5. サービス仕様

### 5.1 `LocationManager`

GPSでのツーリング記録を担当。`CLLocationManagerDelegate` に準拠し、`isRecording && !isPaused` の間のみ位置更新を処理する。

**間引きロジック:**
- 位置更新の精度が `horizontalAccuracy < 50m` を満たさない場合は破棄
- 直前の記録点から **5m以上移動 または 3秒以上経過** した場合のみトラックポイントとして採用（座標配列に追加）
- 距離加算は移動量が **1m以上** の場合のみ（GPSノイズ対策）

**計測項目:**
- `distanceMeters` / `distanceKm`: 有効な位置更新間の距離を積算
- `currentSpeedKmh` / `maxSpeedKmh`: `CLLocation.speed` から算出（m/s → km/h）
- `currentAltitude`: 気圧高度計 利用時はGPS高度で校正した相対値、非利用時はGPS高度をそのまま使用
- `elevationGainMeters`: 気圧高度計利用時は相対高度の増分（`0.05m` 超のみ加算しノイズを除去）、非利用時はGPS高度差分のプラス分のみ加算

**設定との連携（`SettingsStore.shared` 参照）:**
- `accuracyMode`: `.navigation` → `kCLLocationAccuracyBestForNavigation`、`.balanced` → `kCLLocationAccuracyBest`
- `usesBarometricAltimeter`: ON かつ `CMAltimeter.isRelativeAltitudeAvailable()` の場合のみ気圧高度計を使用

**バックグラウンド:** `authorizedAlways` の場合のみ `allowsBackgroundLocationUpdates = true`、記録中はバックグラウンドインジケータを表示。

**権限フロー:** `requestAuthorizationIfNeeded()`（未決定時に使用中許可）、`requestAlwaysIfPossible()`（使用中許可済みなら常に許可へ昇格リクエスト）。`CLLocationManagerDelegate` のコールバックは `nonisolated` にして `MainActor` へホップ（実機でのスレッド問題対策）。

### 5.2 `WeatherManager`

WeatherKit から現在の天気を取得し、設定された間隔（`WeatherUpdateInterval`）でタイマー更新する。

- `start(coordinateProvider:)`: 即座に初回取得し、以後は設定間隔でタイマー実行
- `temperatureCelsius` / `symbolName`（WeatherKitのSFシンボル名）/ `isLoading` を公開
- 取得失敗時は前回値を保持したまま継続（エラーは無視）
- **熱中症警告:** 気温が **30℃以上**、通知設定がON、かつ前回警告から **30分以上経過**している場合に `NotificationManager.postHeatWarning` でローカル通知を送信

### 5.3 `SettingsStore`

`UserDefaults.standard` に保存する `@Observable` シングルトン。全設定値は起動時にデフォルト付きで読み込まれ、変更時に `didSet` で即座に永続化される。CloudKit同期は行わない。

デフォルト値: 単位=km、精度=ナビ用、気圧高度計=ON、天気更新間隔=10分、通知=OFF。

### 5.4 `NotificationManager`

ローカル通知（リモート通知・CloudKit連携なし）の送受信を担当。
- `requestAuthorization`: `.alert, .sound` 権限をリクエスト
- `postHeatWarning`: 熱中症注意の通知を即時発行
- `NotificationPresenter`: フォアグラウンド中も通知をバナー表示させるためのdelegate（`UNUserNotificationCenter.current().delegate` に設定）

## 6. UI共通コンポーネント（`UI/`）

### 6.1 `Theme.swift`

- カラーパレット（ライト/ダーク対応）: `odoAccent`（アクセント青）、`odoBackground`（背景）、`odoCard`（カード背景）
- `SkyGradientBackground`: ホーム・記録中画面用の背景グラデーション（`strong` フラグで濃淡切り替え）
- `BikeMark`: バイクのラインアートアイコン（`Shape`）
- `formatDuration(_:)`: `TimeInterval` を `H:MM:SS` 形式の文字列に変換

### 6.2 `RouteVisuals.swift`

- `RouteShape`: `RouteData` を正規化座標からベジェパスに変換する `Shape`
- `RouteThumbnail`: 56×56の記録一覧用ルートサムネイル（グラデーション背景 + ルート線 + 開始/終了ドット）
- `RouteMapCard`: 記録終了/詳細画面用の`MapKit`地図。実座標の`MapPolyline`と開始/終了マーカーを表示し、座標のバウンディングボックスに1.4倍のマージンを加えた領域を初期表示する

## 7. 権限・エンタイトルメント

| 権限 | Info.plist キー | 用途 |
|---|---|---|
| 位置情報（使用中） | `NSLocationWhenInUseUsageDescription` | 「ツーリング中のルートや距離を記録するために位置情報を使用します。」 |
| 位置情報（常に） | `NSLocationAlwaysAndWhenInUseUsageDescription` | 「バックグラウンドでもツーリングのルートを記録し続けるために『常に許可』が必要です。」 |
| モーション/フィットネス | `NSMotionUsageDescription` | 「気圧高度計を使って走行中の高度・獲得標高を計測するために使用します。」 |
| WeatherKit | `com.apple.developer.weatherkit`（entitlements） | 記録中の天気取得 |
| ローカル通知 | （実行時リクエスト） | 熱中症警告の送信 |

対応デバイス: iPhone（縦固定）、iPad（横固定）。

## 8. 未実装・既知の制約

- 記録名は自動生成（「今日のツーリング」固定）で、ユーザーによる編集・削除UIは未実装
- 記録の削除機能は未実装（`HistoryView` にスワイプ削除等なし）
- ルートサムネイル（`RouteData.diagonal/coastal/winding`）はプリセットとして定義されているが、実データ生成（`fromCoordinates`）に置き換わっており未使用
- CloudKit同期・複数端末間の記録共有には非対応
- テスト（`OdomapTests` / `OdomapUITests`）はXcodeテンプレートの雛形のままで、アプリ固有のテストは未実装
