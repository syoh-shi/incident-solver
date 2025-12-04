# Incident Solver SwiftUI Mock Guide

このリポジトリには、1ファイル完結の SwiftUI モックアップ `IncidentSolver.swift` が含まれています。以下は、Xcode で新規 iOS 17+ プロジェクトを作成した際に、このファイルをどう配置・適用するかの手順です。

## 1. プロジェクトを作成
1. Xcode で **App** テンプレートを選び、言語 **Swift**、インターフェイス **SwiftUI** を指定してプロジェクトを作成します。
2. 最初に生成される `ContentView.swift` と `＜プロジェクト名＞App.swift`（例: `Codex_Incident_RecApp.swift`）は一旦そのままにしておきます。

## 2. ファイルを追加
1. Finder もしくは Xcode のナビゲータで、`IncidentSolver.swift` をプロジェクトの **Sources** 直下（`ContentView.swift` と同じ階層）にコピーします。
2. Xcode ナビゲータで **File > Add Files to "＜プロジェクト名＞"...** を選び、`IncidentSolver.swift` を追加します。ターゲットはメインアプリを選択します。

## 3. エントリポイントを切り替える
1. **重複する @main を避けるため、デフォルトの `＜プロジェクト名＞App.swift` と `ContentView.swift` をターゲットから外すか削除します。**
   - Xcode で各ファイルを選び、右ペインの **Target Membership** のチェックを外す、またはファイル自体を削除してください。
2. もしデフォルトのアプリ定義を残す場合は、`IncidentSolver.swift` 側の `@main struct IncidentSolverApp` を使えるよう、`＜プロジェクト名＞App.swift` 内の `WindowGroup` を `IncidentSolverApp()` に差し替えて、`ContentView.swift` の定義と競合しないようにしてください。

```swift
import SwiftUI

@main
struct Codex_Incident_RecApp: App {
    var body: some Scene {
        WindowGroup {
            IncidentSolverApp()
        }
    }
}
```

## 4. 既存の ContentView を残すかどうか
- `IncidentSolver.swift` は `@main` アプリ定義とすべての画面を内包しているため、プロジェクト内に複数の `@main` が存在しないよう、不要な `App`/`ContentView` 定義を除外してください。
- デモに不要になった `ContentView.swift` は削除しても構いません（削除する場合はターゲットからも外してください）。

## 5. 実行・確認
1. 対象デバイスを iOS 17 以上に設定し、ビルド＆実行します。
2. 起動後、Home で障害カードが表示され、Fact/Action/Map/Search/Settings へ遷移できることを確認します。

## 6. トラブルシュート
- ファイルが見つからない場合は、プロジェクトの Build Phases > Compile Sources に `IncidentSolver.swift` が含まれているか確認してください。
- iOS 16 以下のシミュレータでは動作しないため、必ず iOS 17+ を選択してください。
- Map のアノテーションでビルドエラーが出る場合は、`IncidentSolver.swift` の `MapContainerView` が iOS 17 の `Annotation` 初期化シグネチャ（`content:` クロージャ付き）になっているかを確認してください。

これで `IncidentSolver.swift` を既存の雛形プロジェクトに組み込む準備は完了です。
