---
name: ios-diagnostics
description: ビルドエラー・警告を診断し、原因特定から修正まで行う
allowed-tools:
  - mcp__xcode__XcodeListWindows
  - mcp__xcode__BuildProject
  - mcp__xcode__GetBuildLog
  - mcp__xcode__XcodeListNavigatorIssues
  - mcp__xcode__XcodeRefreshCodeIssuesInFile
  - mcp__xcode__XcodeRead
  - mcp__xcode__XcodeUpdate
  - mcp__xcode__XcodeGrep
  - mcp__xcode__DocumentationSearch
  - mcp__xcode__ExecuteSnippet
argument-hint: "[error | warning | all]"
---

# ビルド診断 & 修正

ビルドエラーや警告を体系的に診断し、原因特定から修正までを行います。

## クイックスタート

`error` → エラーのみ対処。`warning` → 警告のみ対処。`all` または未指定 → 全て対処。

## 手順

### Step 1: ビルドとエラー収集

1. `BuildProject` でビルドを実行
2. `XcodeListNavigatorIssues` で構造化されたエラー/警告を取得:

```json
{
  "tabIdentifier": "...",
  "severity": "error",
  "pattern": null,
  "glob": null
}
```

- `XcodeListNavigatorIssues` が**正規の診断ソース**（重複排除済み・構造化済み）
- `GetBuildLog` は補足情報（生のビルドログ、コンテキスト情報が豊富）

### Step 2: エラーの分類

収集したエラーを以下のカテゴリに分類:

| カテゴリ | 例 | 対処法 |
|----------|-----|--------|
| **型エラー** | Type mismatch, Cannot convert | 型の修正 |
| **参照エラー** | Undefined symbol, Unresolved identifier | import 追加 or 宣言確認 |
| **構文エラー** | Expected expression, Missing return | コード修正 |
| **依存エラー** | No such module | パッケージ設定確認 |
| **Deprecation** | API deprecated | `DocumentationSearch` で代替検索 |

### Step 3: 原因の特定

1. `XcodeRead` でエラー箇所のコードを確認
2. `XcodeRefreshCodeIssuesInFile` で特定ファイルの最新診断を取得:

```json
{
  "tabIdentifier": "...",
  "filePath": "Sources/Services/AuthService.swift"
}
```

3. 必要に応じて `XcodeGrep` で関連コードを検索
4. API の使い方が不明な場合は `DocumentationSearch` で公式ドキュメントを参照

### Step 4: 修正

`XcodeUpdate` でコードを修正する。修正方針:

- **最小限の変更**で問題を解決する
- 周辺コードのリファクタリングは行わない
- 1つのエラーを修正したら次に進む前にビルド検証する

### Step 5: 検証ループ

1. `BuildProject` で再ビルド
2. `XcodeListNavigatorIssues` で残りのエラー/警告を確認
3. 残りがあれば Step 2 に戻る
4. 全て解消したら完了を報告

### Step 6: コードスニペットによる検証（オプション）

修正した API の動作を手軽に確認したい場合は `ExecuteSnippet` を使用:

```json
{
  "tabIdentifier": "...",
  "codeSnippet": "let url = URL(string: \"https://example.com\")!\nprint(url.host())",
  "sourceFilePath": "Sources/Services/NetworkService.swift",
  "timeout": 10000
}
```

- `sourceFilePath` のコンテキスト（import 等）が利用可能
- 簡単な API 動作確認に便利

## ガイドライン

- エラーは依存関係順に修正する（import エラー → 型エラー → ロジックエラー）
- 1つのエラー修正で他のエラーが連鎖的に解消されることがある（特に型推論関連）
- 修正に確信が持てない場合はユーザーに複数の選択肢を提示する
- `GetBuildLog` の `pattern` パラメータで特定のエラーパターンにフォーカスできる
