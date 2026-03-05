---
name: ios-file-ops
description: Xcode MCP のファイル操作ツールを使ったプロジェクト整理・リファクタリング
allowed-tools:
  - mcp__xcode__XcodeListWindows
  - mcp__xcode__XcodeLS
  - mcp__xcode__XcodeGlob
  - mcp__xcode__XcodeGrep
  - mcp__xcode__XcodeRead
  - mcp__xcode__XcodeWrite
  - mcp__xcode__XcodeUpdate
  - mcp__xcode__XcodeRM
  - mcp__xcode__XcodeMV
  - mcp__xcode__XcodeMakeDir
  - mcp__xcode__BuildProject
argument-hint: "[操作内容の説明]"
---

# プロジェクトファイル操作

Xcode MCP のファイル操作ツール群を使い、安全にプロジェクト構造を変更します。

## クイックスタート

操作内容を自然言語で記述すると、適切な MCP ツールの組み合わせで実行します。

## ツール別ベストプラクティス

### XcodeRead — ファイル読み取り

```json
{
  "tabIdentifier": "...",
  "filePath": "Sources/Models/User.swift",
  "offset": 10,
  "limit": 50
}
```

- `offset` と `limit` で部分読み取りが可能（大きなファイルに有効）
- 編集前に必ず読み取りでコンテキストを確認する

### XcodeWrite — ファイル作成

```json
{
  "tabIdentifier": "...",
  "filePath": "Sources/Models/NewModel.swift",
  "content": "import Foundation\n\nstruct NewModel {\n    let id: UUID\n}"
}
```

- **注意**: ターゲットへの自動追加はされない（Xcode 上で手動追加が必要な場合あり）
- 既存ファイルは上書きされるため、事前に `XcodeRead` で確認する

### XcodeUpdate — テキスト置換

```json
{
  "tabIdentifier": "...",
  "filePath": "Sources/Models/User.swift",
  "oldString": "var name: String",
  "newString": "var displayName: String",
  "replaceAll": true
}
```

- `oldString` は完全一致（部分文字列ではなく、十分なコンテキストを含める）
- `replaceAll: false`（デフォルト）は最初の一致のみ置換

### XcodeMV — 移動・リネーム・コピー

```json
{
  "tabIdentifier": "...",
  "sourcePath": "Sources/OldName.swift",
  "destinationPath": "Sources/NewName.swift",
  "operation": "move"
}
```

- `operation`: `"move"` / `"copy"`
- `overwriteExisting`: 既存ファイルの上書き許可

### XcodeRM — 削除

```json
{
  "tabIdentifier": "...",
  "path": "Sources/Deprecated/",
  "recursive": true,
  "deleteFiles": true
}
```

- **破壊的操作**: 必ずユーザーに確認を取ってから実行する
- `deleteFiles: true` でファイルシステムからも削除（false ならプロジェクト参照のみ除去）

### XcodeLS — ディレクトリ一覧

```json
{
  "tabIdentifier": "...",
  "path": "Sources/",
  "recursive": true,
  "ignore": ["*.xcassets", "*.strings"]
}
```

- `ignore` でノイズとなるファイルを除外可能
- プロジェクト構造の全体像を把握するのに使う

### XcodeGlob / XcodeGrep — 検索

```json
// Glob: ファイル名パターンで検索
{ "tabIdentifier": "...", "pattern": "**/*ViewModel.swift" }

// Grep: ファイル内容を正規表現で検索
{ "tabIdentifier": "...", "pattern": "TODO:|FIXME:", "glob": "**/*.swift" }
```

## 安全な操作フロー

### ファイルリネーム（参照の更新込み）

1. `XcodeGrep` で旧ファイル名/クラス名の参照を全検索
2. 参照箇所を `XcodeRead` で確認
3. `XcodeMV` でファイルをリネーム
4. 各参照箇所を `XcodeUpdate` で更新
5. `BuildProject` でビルド検証

### ディレクトリ構造の変更

1. `XcodeLS` で現在の構造を確認
2. `XcodeMakeDir` で新ディレクトリを作成
3. `XcodeMV` でファイルを移動
4. import パスの更新が必要なら `XcodeGrep` + `XcodeUpdate`
5. `BuildProject` でビルド検証

## ガイドライン

- 破壊的操作（RM）は必ずユーザー確認を取る
- ファイル移動後は必ずビルド検証する
- `XcodeWrite` は新規ファイル作成用。既存ファイルの編集には `XcodeUpdate` を使う
- 大量のファイル操作はステップごとにビルド検証を挟む
