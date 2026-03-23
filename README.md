# SwiftUI Pokédex（Flutter → SwiftUI 学習プロジェクト / Claude Code テスト1）

Flutter の Riverpod + Freezed + http による Pokédex 実装を、**SwiftUI で再現する**学習プロジェクトです。  
外部パッケージをほぼ使わず、Apple 標準ライブラリのみで同等の機能を実現しています。

---

## アプリ概要

| 項目 | 内容 |
|------|------|
| プラットフォーム | iOS（SwiftUI）|
| データソース | [PokemonGO-Pokedex JSON](https://raw.githubusercontent.com/Biuni/PokemonGO-Pokedex/master/pokedex.json) |
| 表示対象 | 進化前ポケモン（`prev_evolution` なし）のみ |
| 主な機能 | 一覧表示・タップで進化チェーンダイアログ・詳細情報表示 |
| テーマ | 黒を基調としたダークテーマ |

---

## ファイル構成

```
test_claude_code_swift_ui_1/
├── test_claude_code_swift_ui_1.xcodeproj/   # Xcode プロジェクト設定
├── test_claude_code_swift_ui_1/
│   ├── test_claude_code_swift_ui_1App.swift  # エントリーポイント
│   ├── ContentView.swift                     # UI（View 全体）
│   ├── Pokemon.swift                         # モデル定義
│   ├── PokemonViewModel.swift                # 状態管理
│   └── Assets.xcassets/
├── test_claude_code_swift_ui_1Tests/
├── test_claude_code_swift_ui_1UITests/
└── prompts.md                                # 開発履歴（Flutter↔SwiftUI 対応表）
```

---

## 技術スタック

| Flutter での実装 | SwiftUI での対応 |
|-----------------|-----------------|
| `http` パッケージ | `URLSession.shared`（標準ライブラリ） |
| `freezed` + コード生成 | `struct` + `Codable`（コンパイラ自動合成） |
| `json_serializable` / `@JsonKey` | `CodingKeys` enum |
| Riverpod 2 `@riverpod` | `@Observable`（iOS 17+） |
| `ref.watch(xxxProvider)` | `@State private var viewModel = ...` |
| `ListView.builder` | `List` + `ForEach` |
| `Image.network` / `CachedNetworkImage` | `AsyncImage`（標準） |
| `PageView` | `TabView` + `.tabViewStyle(.page)` |
| `showDialog` | `ZStack` + カスタムオーバーレイ |
| `Wrap` | カスタム `FlowLayout`（`Layout` プロトコル） |
| `GridView.count(crossAxisCount: 2)` | `LazyVGrid` |

---

## 画面構成

### メイン画面（ContentView）

- `NavigationStack` + `List` で一覧表示
- 各行：左側にサムネイル画像（`AsyncImage`）、右側に図鑑番号と名前
- ダークテーマ：`.preferredColorScheme(.dark)` + `.scrollContentBackground(.hidden)`
- `.navigationBarTitleDisplayMode(.inline)` でタイトルをバーに固定

### 進化チェーンダイアログ（EvolutionDialogView）

- リスト行タップで `ZStack` + 半透明オーバーレイとして表示
- 外側の黒背景をタップするとダイアログを閉じる
- `TabView` + `.tabViewStyle(.page)` でページスワイプ

### ポケモン詳細ページ（PokemonDetailPage）

| セクション | 内容 |
|-----------|------|
| 画像 | `AsyncImage`（120×120px）|
| 名前・図鑑番号 | タイトルテキスト |
| タイプバッジ | `HStack` + `Capsule`（タイプ別カラー）|
| ステータスグリッド | `LazyVGrid` 3列（身長・体重・卵・出現時間・出現率・平均出現数）|
| キャンディ | `Image(systemName:)` + テキスト |
| 弱点 | カスタム `FlowLayout` による折り返しバッジ一覧 |

---

## 主要実装

### モデル（Pokemon.swift）

```swift
struct Pokemon: Codable, Identifiable, Sendable {
    let id: Int
    let num: String
    let name: String
    let img: String
    let type: [String]
    let height: String
    let weight: String
    let candy: String?
    let candyCount: Int?
    let egg: String
    let spawnChance: Double
    let avgSpawns: Double
    let spawnTime: String
    let multipliers: [Double]?
    let weaknesses: [String]
    let prevEvolution: [PokemonEvolution]?
    let nextEvolution: [PokemonEvolution]?

    // http:// → https:// に変換（iOS ATS 対応）
    var imageURL: URL? {
        URL(string: img.replacingOccurrences(of: "http://", with: "https://"))
    }
}
```

### 状態管理（PokemonViewModel.swift）

```swift
@Observable
class PokemonViewModel {
    var pokemons: [Pokemon] = []          // 表示用（prevEvolution なしのみ）
    var allPokemonByNum: [String: Pokemon] = [:]  // 進化チェーン構築用
    var isLoading = false
    var errorMessage: String?

    func fetchPokemons() async { ... }

    func evolutionChain(for pokemon: Pokemon) -> [Pokemon] {
        // num をキーに辞書から進化先を検索して配列を構築
    }
}
```

### カスタムオーバーレイダイアログ（ContentView.swift）

```swift
ZStack {
    NavigationStack { ... }

    if let pokemon = selectedPokemon {
        // 半透明背景（タップで閉じる）
        Color.black.opacity(0.6)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedPokemon = nil
                }
            }

        // ダイアログ本体
        EvolutionDialogView(chain: viewModel.evolutionChain(for: pokemon))
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}
```

### カスタム FlowLayout（Wrap 相当）

SwiftUI には Flutter の `Wrap` に相当する標準コンポーネントがないため、`Layout` プロトコル（iOS 16+）を使ってカスタム実装しています。

---

## 開発履歴（プロンプト変更記録）

`prompts.md` に Flutter → SwiftUI 対応の詳細な解説と全変更履歴が記録されています。

| # | 変更内容 |
|---|---------|
| 1 | 基本実装（JSON取得・一覧表示・フィルタリング） |
| 2 | 黒を基調としたダークテーマに変更 |
| 3 | タイトルをナビゲーションバーに固定（`.inline`）|
| 4 | リスト上部の余白を削除（`.listStyle(.plain)`）|
| 5 | タップで進化チェーンのページビューダイアログを表示 |
| 6 | ダイアログにポケモンの詳細情報を追加 |
| 7 | カスタムオーバーレイに変更（外側タップで閉じる）|
| 8 | × ボタン削除・スクロールなし・3列グリッドに調整 |

---

## セットアップ

### 前提条件

- Xcode 16 以上
- iOS 17 以上のシミュレーターまたは実機

### 手順

1. リポジトリをクローン
2. `test_claude_code_swift_ui_1.xcodeproj` を Xcode で開く
3. シミュレーターを選択して実行（⌘R）

外部パッケージの追加・`flutter pub get` 等は不要です。
