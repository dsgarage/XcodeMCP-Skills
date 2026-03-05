# XcodeMCP-Skills

Xcode 26.3 の MCP（Model Context Protocol）ネイティブツール（20個）を活用するための **Claude Code / Claude Agent 用スキル集**です。

```
開発者 → AI エージェント → MCP (mcpbridge) → Xcode 26.3
         "ビルドして"     BuildProject        ビルド実行
         "テストして"     RunSomeTests        テスト実行
         "UI見せて"      RenderPreview       プレビュー取得
```

## クイックスタート

### 1. Xcode MCP を Claude Code に接続（まだの場合）

```bash
claude mcp add --transport stdio xcode -- xcrun mcpbridge
claude mcp list   # xcode が表示されれば OK
```

### 2. スキルをインストール

```bash
git clone https://github.com/dsgarage/XcodeMCP-Skills.git ~/XcodeMCP-Skills
cd ~/XcodeMCP-Skills
./install.sh
```

対話モードで配置先を選択できます。ワンライナーも可能:

```bash
./install.sh --project   # 今のプロジェクトの .claude/skills/ に配置
./install.sh --xcode     # Xcode 内 Claude Agent に配置
./install.sh --cli       # Claude Code CLI グローバルに配置
./install.sh --link      # シンボリックリンクで配置（git pull で自動更新）
```

### 3. 使う

Xcode でプロジェクトを開いた状態で:

```bash
# Claude Code CLI から
claude

> /ios-build-test              # ビルド＆テスト実行
> /ios-build-test --save-log   # 結果を test-results/ にログ保存
> /ios-preview-check           # SwiftUI プレビューを視覚検証
> /ios-diagnostics             # ビルドエラーを診断＆修正
> /ios-simplify                # PR 前のコードレビュー＆品質チェック
> /ios-batch deprecated API を iOS 18 代替に更新  # 大規模マイグレーション
```

## スキル一覧

### 基本スキル

| スキル | 説明 | 主な MCP ツール |
|--------|------|----------------|
| **ios-build-test** | ビルド → テスト → 結果ログ保存 | `BuildProject`, `RunAllTests`, `RunSomeTests`, `GetBuildLog` |
| **ios-preview-check** | SwiftUI プレビューをキャプチャして UI を検証 | `RenderPreview`, `BuildProject` |
| **ios-doc-fix** | Deprecated API を検出 → ドキュメント検索 → 修正 | `DocumentationSearch`, `XcodeGrep`, `XcodeUpdate` |
| **ios-file-ops** | ファイル操作のベストプラクティス集 | `XcodeRead/Write/Update/MV/RM/LS/Glob/Grep` |
| **ios-diagnostics** | ビルドエラー・警告を体系的に診断 → 修正 | `XcodeListNavigatorIssues`, `GetBuildLog`, `ExecuteSnippet` |

### /simplify & /batch 拡張スキル

| スキル | 説明 |
|--------|------|
| **ios-simplify** | `/simplify` の 3 観点レビュー + **ビルド検証** + **プレビュー回帰チェック** + **テストパス確認** + **API 最新性チェック** |
| **ios-batch** | `/batch` の並列マイグレーション + **iOS ガードレール**（.pbxproj 等の変更禁止）+ 各ワーカーで `ios-simplify` 自動適用 |

**ios-simplify の推奨ワークフロー**:

```
実装完了 → git commit → /ios-simplify → git diff 確認 → git commit → PR
```

**ios-batch の活用例**:

```
/ios-batch UIKit の UIAlertController を全て SwiftUI の .alert に移行
/ios-batch Combine の sink/store を async/await に移行
/ios-batch NSNotificationCenter を Observation フレームワークに移行
```

## プロジェクトへの組み込み

### CLAUDE.md テンプレート

`templates/CLAUDE.md.template` に、Xcode Agent と Claude Code CLI の両方に対応した環境適応型テンプレートを用意しています。プロジェクトルートにコピーして編集してください:

```bash
cp ~/XcodeMCP-Skills/templates/CLAUDE.md.template ./CLAUDE.md
# スキーム名、テストターゲット等を自分のプロジェクトに合わせて編集
```

### ディレクトリ構成

```
XcodeMCP-Skills/
├── install.sh                          # インストーラー
├── Makefile                            # make install-* ショートカット
├── skills/
│   ├── ios-build-test/SKILL.md         # ビルド＆テスト
│   ├── ios-preview-check/SKILL.md      # SwiftUI プレビュー検証
│   ├── ios-doc-fix/SKILL.md            # Deprecated API 修正
│   ├── ios-file-ops/SKILL.md           # ファイル操作
│   ├── ios-diagnostics/SKILL.md        # ビルド診断
│   ├── ios-simplify/SKILL.md           # /simplify 拡張
│   └── ios-batch/SKILL.md              # /batch 拡張
└── templates/
    └── CLAUDE.md.template              # プロジェクト用テンプレート
```

## Xcode 26.3 MCP ツールリファレンス

<details>
<summary>全 20 ツール一覧（クリックで展開）</summary>

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

</details>

## 前提条件

- **macOS 26 Tahoe**（Apple Silicon）
- **Xcode 26.3** 以上
- **Claude Code CLI** v2.1.63+ または **Xcode 内 Claude Agent**

## ライセンス

MIT License

## 関連リソース

- [Giving external agentic coding tools access to Xcode | Apple Developer](https://developer.apple.com/documentation/xcode/giving-agentic-coding-tools-access-to-xcode)
- [Meet agentic coding in Xcode | Apple Developer Videos](https://developer.apple.com/videos/play/tech-talks/111428/)
- [Xcode 26.3 MCP tools/list（全20ツール一覧）](https://gist.github.com/keith/d8aca9661002388650cf2fdc5eac9f3b)
- [Claude Code /simplify & /batch 解説（Zenn）](https://zenn.dev/dsgarage/articles/claude-code-simplify-batch)
