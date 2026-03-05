---
name: ios-build-test
description: Xcode MCP でビルド・テスト実行・結果をログファイルに保存する
allowed-tools:
  - mcp__xcode__XcodeListWindows
  - mcp__xcode__BuildProject
  - mcp__xcode__GetBuildLog
  - mcp__xcode__GetTestList
  - mcp__xcode__RunAllTests
  - mcp__xcode__RunSomeTests
  - mcp__xcode__XcodeListNavigatorIssues
  - mcp__xcode__XcodeWrite
  - mcp__xcode__XcodeMakeDir
argument-hint: "[all | テスト名] [--save-log]"
---

# iOS ビルド & テスト

Xcode MCP ツールを使ってビルドとテストを実行し、結果をプロジェクト内にログとして保存します。

## クイックスタート

引数なし → 全テスト実行。テスト名指定 → 特定テストのみ実行。`--save-log` でログ保存。

## 手順

### Step 1: Xcode ウィンドウの検出

`XcodeListWindows` を呼び出して、現在開いているプロジェクトの `tabIdentifier` を取得する。

### Step 2: ビルド

1. `BuildProject` でプロジェクトをビルドする
2. ビルド失敗時:
   - `GetBuildLog` を `severity: "error"` で呼び出してエラーログを取得
   - `XcodeListNavigatorIssues` で Issue Navigator の構造化エラーも取得
   - エラー内容をユーザーに報告して終了

### Step 3: テスト一覧の確認

`GetTestList` でアクティブなテストプランに含まれるテストを一覧表示する。

### Step 4: テスト実行

- **全テスト実行**: 引数が `all` または未指定の場合 → `RunAllTests`
- **特定テスト実行**: テスト名が指定された場合 → `RunSomeTests`

```json
{
  "tabIdentifier": "...",
  "tests": [
    {
      "targetName": "MyAppTests",
      "testIdentifier": "LoginTests/testValidLogin"
    }
  ]
}
```

### Step 5: 結果の確認

テスト結果（パス/フェイル、失敗メッセージ）を確認する。失敗テストがあれば詳細を報告。

### Step 6: ログ保存（--save-log 指定時）

1. `XcodeMakeDir` で `test-results/` ディレクトリを作成（存在しない場合）
2. `XcodeWrite` で以下のフォーマットのログファイルを保存

**ファイル名**: `test-results/YYYY-MM-DD_HHmmss.md`

```markdown
# テスト結果 - {日時}

## サマリー
- スキーム: {scheme名}
- 結果: PASS / FAIL
- 合計: {total} / 成功: {passed} / 失敗: {failed} / スキップ: {skipped}
- 実行時間: {duration}

## 失敗テスト詳細

| ターゲット | テスト名 | エラーメッセージ |
|-----------|----------|-----------------|
| {target}  | {test}   | {message}       |

## ビルドログ（エラー・警告）

{GetBuildLog の severity=error,warning の結果}
```

## ガイドライン

- テスト実行前に必ずビルドを行う（ビルド失敗ならテストは実行しない）
- ログ保存時はタイムスタンプをファイル名に含め、過去のログを上書きしない
- `GetBuildLog` の `pattern` パラメータで特定のエラーパターンをフィルタ可能
- `RunSomeTests` は配列で複数テストを同時指定可能
