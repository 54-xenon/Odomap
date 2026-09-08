# 変更履歴 — `feature/improvements` ブランチ

このドキュメントは `feature/improvements` ブランチで加えた変更をまとめたものです。
（本ブランチはまだコミットされておらず、作業ツリー上の未コミット変更として存在します）

## 概要

記録の閲覧・管理をより使いやすくする機能を追加し、あわせてUIコードの重複を整理しました。

- 記録中にルートをその場で確認できるようになった
- 記録の名前変更・削除ができるようになった
- ホーム画面から直近の記録にすぐアクセスできるようになった
- 名前変更・削除UIをはじめ、地図描画の共通処理を1箇所に集約した

## 追加した機能

### 記録中画面（`RecordView`）

| 変更 | 内容 |
|---|---|
| ライブマップ表示 | `LiveRouteMapCard` を新規追加。記録中、ここまでのルート（青いポリライン）と現在地マーカーをその場で確認できる。現在地取得前は「現在地を取得中…」のプレースホルダーを表示 |
| カメラ追従の間引き | GPS更新のたびにカメラが揺れないよう、前回センタリング地点から **8m以上移動**した場合のみアニメーション付きで再センタリング |
| 画面スリープ防止 | 記録中は `UIApplication.shared.isIdleTimerDisabled = true` により画面の自動ロックを抑止し、画面を離れると元に戻す |
| レイアウト調整 | 中央の大表示を「走行時間」→「現在速度」に変更し、走行時間はメトリクスカードの1つ（`durationCard`）に移動。ライブマップ表示のための余白を確保 |

### ホーム画面（`HomeView`）

| 変更 | 内容 |
|---|---|
| 直近の記録カード | 記録が1件以上ある場合、`RouteThumbnail` ＋ 記録名・日付・距離・走行時間を表示する `recentRideCard` をタイトル下に追加。タップで詳細画面（`RideSummaryView`）へ遷移 |
| ナビゲーション対応 | `NavigationStack` でラップし、カードからの画面遷移に対応 |

### 記録の名前変更・削除（`HistoryView` / `RideSummaryView`）

| 画面 | 操作方法 |
|---|---|
| 記録一覧（`HistoryView`） | 行を長押し（コンテキストメニュー）→「名前を変更」「削除」 |
| 記録詳細（`RideSummaryView`、履歴からの表示時のみ） | ナビゲーションバー右上の「…」メニュー →「名前を変更」「削除」 |

- 名前変更: アラート＋`TextField`。前後の空白をトリムし、空文字なら変更しない
- 削除: `confirmationDialog` で確認後、SwiftDataから削除（詳細画面からの削除時は一覧まで `dismiss()`）

## リファクタリング・コード品質改善

新機能の実装後、`/simplify` によるコードレビュー（重複利用・簡略化・効率・粒度の4観点）を行い、指摘のうち妥当なものを反映しました。

| 分類 | 内容 |
|---|---|
| 重複の解消 | `HistoryView` と `RideSummaryView` にほぼ同一の「名前変更・削除」アラート/確認ダイアログが2重実装されていた（状態の持ち方も `Ride?` と `Bool` で不統一）。`Odomap/UI/RideEditingAlerts.swift` を新規作成し、`rideRenameDeleteAlerts(...)` という共通のViewモディファイアに集約 |
| 重複の解消 | `LiveRouteMapCard` と既存の `RouteMapCard` で同じポリライン線スタイルが2箇所に書かれていたため、`StrokeStyle.routeLine` として共通化 |
| 効率改善 | `RouteThumbnail` が `ride.route`（GPS座標の正規化計算を伴う重い処理）を描画のたびに3回呼んでいたのを、1回だけ計算してローカル変数で使い回すよう変更 |
| 効率改善 | `LiveRouteMapCard` のカメラ再センタリングが、GPS更新のたびに（ほぼ毎秒）アニメーション付きで発火していたのを、8m以上移動した場合のみに間引き（カメラのガタつき防止） |
| 整理 | `HomeView.swift` の余分な空行を削除 |

### あえて手を付けなかった点

- `RecordView` の `UIApplication.shared.isIdleTimerDisabled` をview lifecycle内に書いている点は「`LocationManager` に移すべき」という指摘があったが、GPS管理クラスに画面スリープ制御というUI関心事を持ち込むと責務が濁ると判断し、現状維持とした
- `Map` の `MapPolyline` が毎フレーム全座標から再構築される点はSwiftUIのMapKit APIの制約によるもので、修正には `UIViewRepresentable` による `MKMapView` の手動管理という大きな設計変更が必要なため、スコープ外とした

## ドキュメント更新

- `README.md` / `docs/SPEC.md`: 新機能（ライブマップ、名前変更・削除、直近の記録カード、画面スリープ防止）を反映
- `docs/SPEC.md`: `RideEditingAlerts.swift` の追加、ライブマップの再センタリング仕様（8m閾値）、共通線スタイルの導入をアーキテクチャ節・UIコンポーネント節に追記

## 変更ファイル一覧

```
Odomap/Screens/ContentView.swift        # HomeView に rides を渡すよう変更
Odomap/Screens/HistoryView.swift        # 名前変更・削除メニューを追加、共通アラートを利用
Odomap/Screens/HomeView.swift           # 直近の記録カードを追加
Odomap/Screens/RecordView.swift         # ライブマップ・画面スリープ防止・レイアウト変更
Odomap/Screens/RideSummaryView.swift    # 名前変更・削除メニューを追加、共通アラートを利用
Odomap/Services/SettingsStore.swift     # コメント修正のみ
Odomap/UI/RouteVisuals.swift            # LiveRouteMapCard 追加、共通スタイル・キャッシュ・間引き
Odomap/UI/RideEditingAlerts.swift       # 新規: 名前変更・削除アラートの共通化
README.md                               # 新機能・構成の反映
docs/SPEC.md                            # 新機能・構成の反映
```
