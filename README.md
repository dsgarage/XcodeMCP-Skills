# XcodeMCP-Skills

Xcode 26.3 の MCP（Model Context Protocol）ネイティブツールを最大限に活用するための Claude Code / Claude Agent 用スキル集です。

## 概要

Xcode 26.3 は 20 個のビルトイン MCP ツールを搭載しています。これらのツールを効果的に使うためのスキルを提供します。

### 提供スキル一覧

| スキル名 | 説明 | 用途 |
|----------|------|------|
| `ios-build-test` | ビルド・テスト実行・結果ログ保存 | CI的な自動テストワークフロー |
| `ios-preview-check` | SwiftUI プレビューのキャプチャ・検証 | UI のビジュアルチェックループ |
| `ios-doc-fix` | Deprecated API 検出・ドキュメント検索・修正 | API マイグレーション |
| `ios-file-ops` | プロジェクト内ファイル操作のベストプラクティス | リファクタリング・ファイル整理 |
| `ios-diagnostics` | ビルドエラー・警告の診断と修正 | デバッグ・コード品質改善 |
| `ios-simplify` | /simplify の Xcode MCP 拡張版。レビュー＋ビルド検証＋プレビュー回帰＋テスト確認 | PR 前の最終仕上げ |
| `ios-batch` | /batch の Xcode MCP 拡張版。大規模変更の自動分解・並列実行・ビルド検証 | API マイグレーション・アーキテクチャ移行 |

## セットアップ

### 方法 1: Xcode 内 Claude Agent に配置

```bash
# スキルディレクトリにクローン
git clone https://github.com/dsgarage/XcodeMCP-Skills.git /tmp/XcodeMCP-Skills

# Xcode の ClaudeAgentConfig にコピー
cp -r /tmp/XcodeMCP-Skills/skills/* \
  ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/skills/
```

### 方法 2: Claude Code CLI で使用

```bash
# プロジェクトの .claude/skills/ にコピー
cp -r /tmp/XcodeMCP-Skills/skills/* .claude/skills/
```

### 方法 3: シンボリックリンクで共有（推奨）

CLI と Xcode の両方で同じスキルを使えます：

```bash
# 任意の場所にクローン
git clone https://github.com/dsgarage/XcodeMCP-Skills.git ~/XcodeMCP-Skills

# Xcode Agent 用
ln -s ~/XcodeMCP-Skills/skills/ios-build-test \
  ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/skills/ios-build-test

# Claude Code CLI 用（プロジェクト単位）
ln -s ~/XcodeMCP-Skills/skills/ios-build-test .claude/skills/ios-build-test
```

## Xcode 26.3 MCP ツールリファレンス

本スキルが利用する Xcode ネイティブ MCP ツール一覧：

### ファイル操作

| ツール | 説明 |
|--------|------|
| `XcodeRead` | ファイル内容を行番号付きで読み取り |
| `XcodeWrite` | ファイルの新規作成・上書き |
| `XcodeUpdate` | テキスト置換による編集（str_replace 方式） |
| `XcodeRM` | ファイル/ディレクトリの削除 |
| `XcodeMV` | 移動・リネーム・コピー |
| `XcodeMakeDir` | ディレクトリ/グループ作成 |
| `XcodeLS` | ディレクトリ内容一覧 |
| `XcodeGlob` | ワイルドカードによるファイル検索 |
| `XcodeGrep` | 正規表現でファイル内テキスト検索 |

### ビルド・テスト

| ツール | 説明 |
|--------|------|
| `BuildProject` | プロジェクトビルド |
| `GetBuildLog` | ビルドログ取得（severity/pattern フィルタ対応） |
| `RunAllTests` | 全テスト実行 |
| `RunSomeTests` | 特定テスト実行（ターゲット＋テスト ID 指定） |
| `GetTestList` | テストプランのテスト一覧取得 |

### 診断・その他

| ツール | 説明 |
|--------|------|
| `XcodeListNavigatorIssues` | Issue Navigator の警告/エラー取得 |
| `XcodeRefreshCodeIssuesInFile` | 特定ファイルのコンパイラ診断 |
| `ExecuteSnippet` | コードスニペットのビルド＆実行 |
| `DocumentationSearch` | Apple 公式ドキュメント検索 |
| `RenderPreview` | SwiftUI プレビューのスクリーンショット取得 |
| `XcodeListWindows` | Xcode ウィンドウ一覧（tabIdentifier 取得用） |

## /simplify & /batch 連携

Xcode MCP 環境向けに、Claude Code の `/simplify` と `/batch` スキルを拡張した `ios-simplify` / `ios-batch` を提供しています。

### ios-simplify

標準の `/simplify`（再利用性・品質・効率性の 3 エージェントレビュー）に加え、Xcode MCP ツールで以下を自動検証します:

- `BuildProject` — コンパイル検証
- `RenderPreview` — SwiftUI プレビューの回帰チェック
- `RunSomeTests` — 関連テストのパス確認
- `XcodeListNavigatorIssues` — 警告の増減チェック
- `DocumentationSearch` — deprecated API の検出

**推奨ワークフロー**: `実装 → commit → /ios-simplify → diff 確認 → commit → PR`

### ios-batch

標準の `/batch`（調査→分解→並列実行→PR 作成）を iOS プロジェクト向けに拡張:

- `XcodeGrep` / `XcodeGlob` で影響範囲を正確に把握
- 各ワーカーが `BuildProject` + `RunSomeTests` でビルド＆テスト検証
- iOS 固有のガードレール（`.pbxproj` / `Info.plist` / `.entitlements` 等の変更禁止）
- 各ワーカーの変更に `ios-simplify` を自動適用

**活用例**:
```bash
/ios-batch UIKit の UIAlertController を全て SwiftUI の .alert に移行
/ios-batch Combine の sink/store を async/await に移行
/ios-batch iOS 17 deprecated API を iOS 18 代替 API に更新
```

## 前提条件

- macOS 26 Tahoe（Apple Silicon）
- Xcode 26.3 以上
- Claude Code CLI または Xcode 内 Claude Agent

## CLAUDE.md テンプレート

プロジェクトルートに配置する `CLAUDE.md` のテンプレートを `templates/CLAUDE.md.template` に用意しています。Xcode Agent と Claude Code CLI の両方に対応した環境適応型の記述例です。

## ライセンス

MIT License

## 関連リソース

- [Giving external agentic coding tools access to Xcode | Apple Developer](https://developer.apple.com/documentation/xcode/giving-agentic-coding-tools-access-to-xcode)
- [Meet agentic coding in Xcode | Apple Developer Videos](https://developer.apple.com/videos/play/tech-talks/111428/)
- [Xcode 26.3 MCP tools/list（全20ツール一覧）](https://gist.github.com/keith/d8aca9661002388650cf2fdc5eac9f3b)
