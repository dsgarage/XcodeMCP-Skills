---
name: ios-preview-check
description: SwiftUI プレビューをキャプチャして視覚的に UI を検証する
allowed-tools:
  - mcp__xcode__XcodeListWindows
  - mcp__xcode__XcodeRead
  - mcp__xcode__XcodeUpdate
  - mcp__xcode__BuildProject
  - mcp__xcode__RenderPreview
  - mcp__xcode__XcodeGlob
argument-hint: "[ファイルパス or ワイルドカード]"
---

# SwiftUI プレビュー検証

SwiftUI プレビューのスクリーンショットを取得し、UI の問題を検出・修正するループを回します。

## クイックスタート

ファイルパス指定 → そのファイルのプレビューを検証。未指定 → `*Preview*.swift` を検索して対象を選択。

## 手順

### Step 1: 対象ファイルの特定

- ファイルパス指定あり → そのまま使用
- 未指定 → `XcodeGlob` で `**/*Preview*.swift` や `**/*View.swift` を検索して候補を提示

### Step 2: ソースコードの確認

`XcodeRead` で対象ファイルを読み、`#Preview` マクロの定義を確認する。
- プレビュー定義が複数ある場合は `previewDefinitionIndexInFile` で区別
- プレビュー定義がない場合はユーザーに報告

### Step 3: ビルド

`BuildProject` でプロジェクトをビルドする。ビルドが通らなければプレビューは取得できない。

### Step 4: プレビューキャプチャ

`RenderPreview` を呼び出す:

```json
{
  "tabIdentifier": "...",
  "sourceFilePath": "Sources/Views/ContentView.swift",
  "previewDefinitionIndexInFile": 0,
  "timeout": 30000
}
```

- 返されるスクリーンショットを分析する
- 複数のプレビュー定義がある場合は順番にキャプチャ

### Step 5: UI 問題の検出と報告

以下の観点でスクリーンショットを確認:

- **レイアウト**: 要素の重なり、はみ出し、不自然な余白
- **テキスト**: 文字切れ、フォントサイズの不整合
- **色**: コントラスト不足、ダークモード対応
- **アクセシビリティ**: タップ領域の大きさ、テキストの読みやすさ

### Step 6: 修正と再検証（問題があった場合）

1. `XcodeUpdate` で SwiftUI コードを修正
2. `BuildProject` で再ビルド
3. `RenderPreview` で再キャプチャ
4. 問題が解消するまでループ

## ガイドライン

- `previewDefinitionIndexInFile` は 0 始まり
- `timeout` はデフォルト 30 秒だが、複雑なプレビューでは増やすことを検討
- ダークモード用プレビューがある場合はそちらも必ず確認
- プレビューのスクリーンショットはエージェントが視覚的に判断する（画像として返される）
