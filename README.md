# Odomap

Odomap（オドマップ）は、バイク／自転車ツーリングの走行記録を GPS で自動計測する iOS アプリです。走行中の距離・速度・獲得標高・天気をリアルタイムに表示し、走行終了後はルート地図付きのサマリーとして保存・閲覧できます。

## 主な機能

- GPS による走行距離・速度・獲得標高のリアルタイム計測
- 気圧高度計（Core Motion）を使った高精度な獲得標高計測（GPS高度へのフォールバックあり）
- WeatherKit 連携によるリアルタイム天気表示・熱中症警告通知
- 走行ルートを地図上に可視化したサマリー画面
- 過去の走行記録一覧・詳細閲覧
- 距離／速度の単位（km・mi）、精度優先モード、天気更新間隔などの設定

## 技術スタック

- プラットフォーム: iOS（SwiftUI, iOS 26 系 API — `glassEffect` 使用）
- 永続化: SwiftData（ローカルのみ、CloudKit 同期なし）
- 位置情報: Core Location（バックグラウンド追跡対応）
- 高度計測: Core Motion（気圧高度計）
- 天気: WeatherKit
- 通知: UserNotifications（ローカル通知のみ）
- 言語: Swift 5、状態管理は `Observation`（`@Observable`）
- 対応言語: 日本語（UI文言・日付フォーマットは `ja_JP` 固定）
- 対応向き: iPhone は縦固定、iPad は横固定

## 動作環境

- iOS 26.5 以降
- Xcode（iOS 26 SDK）

## セットアップ

```bash
git clone <このリポジトリのURL>
cd Odomap
open Odomap.xcodeproj
```

Xcode でビルド・実行してください。WeatherKit を利用するため、実機/シミュレータともに Apple Developer アカウントに紐づいた署名設定と `com.apple.developer.weatherkit` エンタイトルメントが必要です。

## プロジェクト構成

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

詳細な仕様は [docs/SPEC.md](docs/SPEC.md) を参照してください。

## テスト

```bash
xcodebuild test -project Odomap.xcodeproj -scheme Odomap -destination 'platform=iOS Simulator,name=iPhone 17'
```

`OdomapTests` / `OdomapUITests` は現状 Xcode テンプレートの雛形のままで、アプリ固有のテストは未実装です。

## 権限

| 権限 | 用途 |
|---|---|
| 位置情報（使用中） | ツーリング中のルートや距離の記録 |
| 位置情報（常に） | バックグラウンドでのルート記録継続 |
| モーション/フィットネス | 気圧高度計による高度・獲得標高の計測 |
| 通知 | 熱中症警告の送信 |

## 既知の制約

- 記録名は自動生成（「今日のツーリング」固定）で、編集・削除UIは未実装
- 記録の削除機能は未実装
- CloudKit同期・複数端末間の記録共有には非対応

詳細は [docs/SPEC.md](docs/SPEC.md) の「未実装・既知の制約」を参照してください。
