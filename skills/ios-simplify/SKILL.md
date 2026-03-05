---
name: ios-simplify
description: /simplify の Xcode MCP 拡張版。変更コードのレビュー＋ビルド検証＋プレビュー回帰チェック＋テストパス確認
allowed-tools:
  - mcp__xcode__XcodeListWindows
  - mcp__xcode__XcodeRead
  - mcp__xcode__XcodeUpdate
  - mcp__xcode__XcodeGrep
  - mcp__xcode__XcodeGlob
  - mcp__xcode__BuildProject
  - mcp__xcode__GetBuildLog
  - mcp__xcode__RunSomeTests
  - mcp__xcode__GetTestList
  - mcp__xcode__RenderPreview
  - mcp__xcode__XcodeListNavigatorIssues
  - mcp__xcode__DocumentationSearch
  - mcp__xcode__XcodeRefreshCodeIssuesInFile
---

# iOS Simplify — Xcode MCP 拡張コードレビュー

標準の `/simplify`（再利用性・品質・効率性の3エージェントレビュー）に加え、
Xcode MCP ツールを使って **ビルド検証・UI 回帰チェック・テストパス確認** まで行います。

## いつ使うか

- 実装が完了し、PR を出す前の最終仕上げ
- 長時間セッション後のコード整理
- `/simplify` の結果を iOS プロジェクト固有の観点で補強したいとき

## 推奨ワークフロー

```
実装完了 → git commit → /ios-simplify → git diff 確認 → git commit → PR 作成
```

## 手順

### Phase 1: 変更ファイルの特定

git diff で変更されたファイルを特定する。Swift ファイル（`.swift`）のみを対象とする。

### Phase 2: 3 観点レビュー（/simplify 準拠）

変更された各ファイルに対して、以下の 3 観点でレビューを行う。

#### 2-1. 再利用性（Code Reuse）

`XcodeGrep` で変更コード内のパターンを検索し、プロジェクト内の重複を検出:

- 同じロジックが複数箇所に存在しないか
- 既存のユーティリティ関数やエクステンションで代替できないか
- Protocol のデフォルト実装で共通化できるパターンがないか

```json
{
  "tabIdentifier": "...",
  "pattern": "URLSession\\.shared\\.data",
  "glob": "**/*.swift"
}
```

#### 2-2. コード品質（Code Quality）

`XcodeRead` で変更ファイルを読み、以下を確認:

- 命名規則（Swift API Design Guidelines 準拠）
- 関数の分解（1関数 = 1責務）
- 制御フローの明確さ（早期リターン、guard の適切な使用）
- アクセス制御（不要な public/internal の検出）

#### 2-3. 効率性（Efficiency）

変更コードの効率を確認:

- 不要なイテレーション（`filter` + `first` → `first(where:)` 等）
- 見落とした async/await の機会
- 不要な `@MainActor` の付与
- メモリリークのリスク（クロージャ内の `[weak self]` 漏れ）

### Phase 3: iOS 固有チェック（Xcode MCP 拡張）

#### 3-1. ビルド検証

`BuildProject` でビルドを実行。通らなければ Phase 2 の修正に問題がある。

```
BuildProject → 成功 → Phase 3-2 へ
            → 失敗 → GetBuildLog(severity: "error") で原因特定 → 修正 → 再ビルド
```

#### 3-2. コンパイラ警告チェック

`XcodeListNavigatorIssues` で新たな警告が増えていないか確認:

```json
{
  "tabIdentifier": "...",
  "severity": "warning"
}
```

変更前より警告が増えている場合は修正する。

#### 3-3. SwiftUI プレビュー回帰チェック

変更ファイルに `#Preview` マクロが含まれている場合、`RenderPreview` でスクリーンショットを取得:

- レイアウト崩れがないか視覚的に確認
- 変更前の意図したデザインから逸脱していないか

#### 3-4. テストパス確認

`GetTestList` で変更に関連するテストを特定し、`RunSomeTests` で実行:

- 変更ファイルに対応するテストファイル（`*Tests.swift`）を検索
- 対応テストが見つからない場合はスキップ（テストがないことをユーザーに報告）

#### 3-5. API 最新性チェック

`DocumentationSearch` で変更コード内の主要 API が最新か確認:

- deprecated API を新たに導入していないか
- より適切な新しい API が存在しないか

### Phase 4: レポートと修正適用

全チェックの結果をサマリーとして報告:

```
## /ios-simplify レポート

### 再利用性
- [修正] NetworkService.swift: fetchData() の重複を shared extension に統合
- [OK] UserViewModel.swift: 重複なし

### 品質
- [修正] LoginView.swift: guard let に変更（早期リターン）
- [OK] ProfileView.swift: 命名規則準拠

### 効率性
- [修正] SearchService.swift: filter+first → first(where:) に変更

### Xcode MCP 検証
- ビルド: PASS
- 警告: 0 件（増減なし）
- プレビュー: LoginView — OK, ProfileView — OK
- テスト: 12/12 パス
- API 最新性: 問題なし
```

## ガイドライン

- **機能を変えない**: リファクタリングのみ。ロジックの変更は行わない
- **修正は最小限**: 変更されたファイルのみ対象。周辺ファイルは触らない
- **必ず git diff で確認**: 自動修正後はユーザーに差分を確認してもらう
- **iOS 固有の注意点**:
  - `@Published` → `@Observable` への変換は機能変更になるため行わない
  - `SerializedField` 相当（`@IBOutlet`, `@IBAction`）の変更は Interface Builder 参照に影響するため慎重に
  - SwiftUI の `body` 内の構造変更はプレビューで必ず確認
