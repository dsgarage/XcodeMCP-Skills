---
name: ios-doc-fix
description: Deprecated API を検出し、Apple 公式ドキュメントで代替を検索して修正する
allowed-tools:
  - mcp__xcode__XcodeListWindows
  - mcp__xcode__XcodeListNavigatorIssues
  - mcp__xcode__DocumentationSearch
  - mcp__xcode__XcodeGrep
  - mcp__xcode__XcodeRead
  - mcp__xcode__XcodeUpdate
  - mcp__xcode__BuildProject
  - mcp__xcode__GetBuildLog
argument-hint: "[フレームワーク名 or API名]"
---

# Deprecated API 検出 & 修正

Xcode の Issue Navigator から deprecation 警告を収集し、Apple 公式ドキュメントで代替 API を検索、一括修正します。

## クイックスタート

引数なし → プロジェクト全体の deprecation 警告を修正。フレームワーク/API 名指定 → 対象を絞って修正。

## 手順

### Step 1: Deprecation 警告の収集

`XcodeListNavigatorIssues` を呼び出す:

```json
{
  "tabIdentifier": "...",
  "severity": "warning",
  "pattern": "deprecated|unavailable"
}
```

警告がない場合は「Deprecated API は見つかりませんでした」と報告して終了。

### Step 2: 代替 API の検索

各 deprecated API について `DocumentationSearch` で代替を検索:

```json
{
  "query": "UITableView replacement SwiftUI",
  "frameworks": ["SwiftUI", "UIKit"]
}
```

- `frameworks` パラメータで対象フレームワークを絞ると精度が上がる
- WWDC トランスクリプトも検索対象に含まれるため、移行ガイドが見つかりやすい

### Step 3: 使用箇所の全数把握

`XcodeGrep` で deprecated API の使用箇所を全て検索:

```json
{
  "tabIdentifier": "...",
  "pattern": "UITableView",
  "glob": "**/*.swift"
}
```

### Step 4: コードの確認と修正

1. `XcodeRead` で該当ファイルのコンテキストを確認
2. `XcodeUpdate` で修正を適用:

```json
{
  "tabIdentifier": "...",
  "filePath": "Sources/Views/ListView.swift",
  "oldString": "UITableView()",
  "newString": "List { ... }",
  "replaceAll": false
}
```

- `replaceAll: true` で同一ファイル内の全出現を一括置換可能
- ただし、コンテキストによって置換内容が異なる場合は個別に処理する

### Step 5: ビルド検証

1. `BuildProject` でビルド
2. `GetBuildLog` で新たなエラーが発生していないか確認
3. `XcodeListNavigatorIssues` で残りの deprecation 警告を再チェック
4. 残りがあれば Step 2 に戻る

## ガイドライン

- 一度に全ての deprecated API を修正しようとせず、1つずつ確実に修正・ビルド検証する
- API の互換性（最小デプロイターゲット）を考慮する
- 大規模な API 変更（UIKit → SwiftUI 移行など）は影響範囲を報告し、ユーザーの確認を取る
- `DocumentationSearch` は Apple 公式ドキュメントと WWDC セッションの両方を検索する
