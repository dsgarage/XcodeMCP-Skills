---
name: ios-batch
description: /batch の Xcode MCP 拡張版。大規模 iOS コード変更を自動分解・並列実行・ビルド検証・PR 作成
allowed-tools:
  - mcp__xcode__XcodeListWindows
  - mcp__xcode__XcodeRead
  - mcp__xcode__XcodeWrite
  - mcp__xcode__XcodeUpdate
  - mcp__xcode__XcodeGrep
  - mcp__xcode__XcodeGlob
  - mcp__xcode__XcodeLS
  - mcp__xcode__BuildProject
  - mcp__xcode__GetBuildLog
  - mcp__xcode__RunAllTests
  - mcp__xcode__RunSomeTests
  - mcp__xcode__GetTestList
  - mcp__xcode__XcodeListNavigatorIssues
  - mcp__xcode__DocumentationSearch
  - mcp__xcode__RenderPreview
argument-hint: "<マイグレーション内容の説明>"
---

# iOS Batch — Xcode MCP 拡張並列マイグレーション

標準の `/batch`（調査→分解→並列実行→PR 作成）を iOS プロジェクト向けに拡張。
Xcode MCP ツールで **影響範囲の正確な把握・各ワーカーでのビルド検証・iOS 固有のガードレール** を提供します。

## いつ使うか

- iOS プロジェクト全体に影響する大規模な変更
- 例: UIKit → SwiftUI 移行、deprecated API の一括更新、アーキテクチャ移行

## 活用シナリオ

```
/ios-batch UIKit の UIAlertController を全て SwiftUI の .alert modifier に移行してください
/ios-batch iOS 17 deprecated API を iOS 18 の代替 API に更新
/ios-batch 全ての ViewController を MVVM + SwiftUI に段階移行
/ios-batch Combine の sink/store パターンを async/await に移行
/ios-batch NSNotificationCenter を Observation フレームワークに移行
```

## 手順

### Phase 1: 調査（Research）

#### 1-1. 影響範囲の特定

`XcodeGrep` と `XcodeGlob` で対象コードを網羅的に検索:

```json
// 例: UIAlertController の使用箇所を全検索
{
  "tabIdentifier": "...",
  "pattern": "UIAlertController",
  "glob": "**/*.swift"
}
```

#### 1-2. 依存関係の解析

`XcodeRead` で各ファイルの import と型参照を確認し、依存グラフを構築:

- どのファイルがどのモジュールに依存しているか
- 変更の影響が波及するファイルはどれか

#### 1-3. Apple 公式ドキュメントで移行先を確認

`DocumentationSearch` で移行先 API のベストプラクティスを検索:

```json
{
  "query": "migrate UIAlertController to SwiftUI alert",
  "frameworks": ["SwiftUI", "UIKit"]
}
```

### Phase 2: 計画（Plan）

#### 2-1. 独立ユニットへの分解

調査結果を基に、5〜30 の独立した作業ユニットに分解する。

**分解の原則:**
- 1 ユニット = 1〜5 ファイルの変更
- ユニット間に依存関係がないこと（並列実行可能）
- 各ユニットが単独でビルド可能であること

**iOS 固有の分解ルール:**
- **ターゲット境界を尊重**: 異なるターゲット（App / Extension / Framework）のファイルは別ユニット
- **Storyboard/XIB 参照**: IB 参照があるファイルは関連する IB ファイルと同一ユニット
- **SwiftUI プレビュー**: プレビュー付きの View は変更後の視覚確認を含める

#### 2-2. 計画の提示

以下のフォーマットでユーザーに計画を提示し、承認を得る:

```
## /ios-batch 実行計画

### マイグレーション: {内容}
### 影響ファイル数: {N} ファイル
### ユニット数: {M} ユニット

| # | ユニット名 | 対象ファイル | 検証方法 |
|---|-----------|-------------|---------|
| 1 | LoginFlow | LoginVC.swift, LoginVM.swift | ビルド + LoginTests |
| 2 | ProfileFlow | ProfileVC.swift | ビルド + プレビュー |
| ... | ... | ... | ... |

### iOS ガードレール
- .pbxproj: 変更しない
- Info.plist: 変更なし
- Entitlements: 変更なし

承認しますか？ [Y/n]
```

### Phase 3: 並列実行（Execute）

ユーザーの承認後、各ユニットをワーカーとして並列実行する。

#### 各ワーカーの処理フロー:

```
1. git worktree で独立ブランチを作成
2. XcodeUpdate でコード変更を適用
3. BuildProject でビルド検証
   → 失敗: GetBuildLog でエラー取得 → 修正 → 再ビルド
4. RunSomeTests で関連テスト実行
   → 失敗: テスト修正 → 再テスト
5. RenderPreview で SwiftUI プレビュー確認（該当ファイルのみ）
6. /ios-simplify を実行（コード品質の自動改善）
7. git commit & push
8. gh pr create で PR 作成
```

#### iOS 固有のガードレール

各ワーカーは以下を**絶対に変更しない**:

| ファイル | 理由 |
|---------|------|
| `*.pbxproj` | Xcode プロジェクト設定の破損リスク |
| `Info.plist` | アプリ設定への意図しない影響 |
| `*.entitlements` | 権限設定の変更は別作業 |
| `*.xcdatamodeld` | Core Data モデルはマイグレーション戦略が必要 |
| `*.storyboard` / `*.xib` | IB ファイルの自動変更は参照破壊のリスク |

これらの変更が必要な場合は、ワーカーは変更をスキップしてユーザーに手動対応を報告する。

### Phase 4: 進捗追跡と完了

#### 4-1. ステータステーブル

```
## /ios-batch 進捗

| # | ユニット | ビルド | テスト | プレビュー | PR |
|---|---------|-------|-------|-----------|-----|
| 1 | LoginFlow | PASS | 5/5 | OK | #42 |
| 2 | ProfileFlow | PASS | 3/3 | OK | #43 |
| 3 | SettingsFlow | FAIL | - | - | - |
| ... | ... | ... | ... | ... | ... |

失敗ユニット: 1 件（SettingsFlow — ビルドエラー、手動対応推奨）
```

#### 4-2. 完了レポート

```
## /ios-batch 完了レポート

- 成功: {N}/{M} ユニット
- 作成 PR: #42, #43, #44, ...
- 手動対応必要: SettingsFlow（ビルドエラー: CoreData モデル変更が必要）
- 推定節約時間: {手作業の見積もり} → {実行時間}
```

## ガイドライン

- **計画は必ずユーザー承認**: 自動実行しない。計画を提示して承認を得てから実行
- **ガードレールは厳守**: `.pbxproj` 等の変更禁止ファイルは絶対に変更しない
- **1 ユニットの失敗で全体を止めない**: 失敗ユニットをスキップして報告、他は続行
- **各ワーカーで /ios-simplify**: PR 品質を担保するため、各ワーカーの変更にレビューを適用
- **大規模すぎる場合は分割提案**: 100 ファイル超のマイグレーションは複数回に分けることを提案
