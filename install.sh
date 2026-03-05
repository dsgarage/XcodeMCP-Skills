#!/bin/bash
# XcodeMCP-Skills インストーラー
# 使い方: ./install.sh [オプション]
#   --xcode    Xcode 内 Claude Agent に配置
#   --cli      Claude Code CLI のグローバルスキルに配置
#   --project  現在のプロジェクトの .claude/skills/ に配置
#   --link     シンボリックリンクで配置（更新が自動反映）
#   (オプションなし → 対話モード)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
XCODE_SKILLS_DIR="$HOME/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/skills"
CLI_SKILLS_DIR="$HOME/.claude/skills"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

count_skills() {
  ls -d "$SKILLS_DIR"/*/SKILL.md 2>/dev/null | wc -l | tr -d ' '
}

install_copy() {
  local dest="$1"
  mkdir -p "$dest"
  for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "$dest/$skill_name"
    cp "$skill_dir/SKILL.md" "$dest/$skill_name/SKILL.md"
    log "$skill_name → $dest/$skill_name/"
  done
}

install_link() {
  local dest="$1"
  mkdir -p "$dest"
  for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    target="$dest/$skill_name"
    if [ -L "$target" ]; then
      rm "$target"
    elif [ -d "$target" ]; then
      warn "$target は既存ディレクトリです。スキップします。--link を使う場合は先に削除してください。"
      continue
    fi
    ln -s "$(cd "$skill_dir" && pwd)" "$target"
    log "$skill_name → $target (symlink)"
  done
}

echo ""
echo "=== XcodeMCP-Skills インストーラー ==="
echo "スキル数: $(count_skills) 個"
echo ""

case "${1:-}" in
  --xcode)
    echo "Xcode Agent に配置します..."
    install_copy "$XCODE_SKILLS_DIR"
    echo ""
    log "完了。Xcode を再起動してください。"
    ;;
  --cli)
    echo "Claude Code CLI グローバルスキルに配置します..."
    install_copy "$CLI_SKILLS_DIR"
    echo ""
    log "完了。新しい Claude Code セッションから有効です。"
    ;;
  --project)
    if [ ! -d ".git" ]; then
      warn "カレントディレクトリが git リポジトリではありません。"
      exit 1
    fi
    echo "現在のプロジェクトに配置します..."
    install_copy ".claude/skills"
    echo ""
    log "完了。.claude/skills/ にスキルを配置しました。"
    ;;
  --link)
    echo "配置先を選んでください:"
    echo "  1) Xcode Agent ($XCODE_SKILLS_DIR)"
    echo "  2) Claude Code CLI ($CLI_SKILLS_DIR)"
    echo "  3) 両方"
    read -rp "選択 [1-3]: " choice
    case "$choice" in
      1) install_link "$XCODE_SKILLS_DIR" ;;
      2) install_link "$CLI_SKILLS_DIR" ;;
      3) install_link "$XCODE_SKILLS_DIR"; install_link "$CLI_SKILLS_DIR" ;;
      *) echo "不正な選択です"; exit 1 ;;
    esac
    echo ""
    log "完了。シンボリックリンクで配置しました（git pull で自動更新されます）。"
    ;;
  *)
    echo "配置先を選んでください:"
    echo "  1) Xcode Agent（コピー）"
    echo "  2) Claude Code CLI グローバル（コピー）"
    echo "  3) 現在のプロジェクト（コピー）"
    echo "  4) Xcode + CLI 両方（シンボリックリンク・推奨）"
    echo ""
    read -rp "選択 [1-4]: " choice
    case "$choice" in
      1) install_copy "$XCODE_SKILLS_DIR"
         log "完了。Xcode を再起動してください。" ;;
      2) install_copy "$CLI_SKILLS_DIR"
         log "完了。" ;;
      3)
        if [ ! -d ".git" ]; then
          warn "カレントディレクトリが git リポジトリではありません。"
          exit 1
        fi
        install_copy ".claude/skills"
        log "完了。" ;;
      4) install_link "$XCODE_SKILLS_DIR"
         install_link "$CLI_SKILLS_DIR"
         log "完了。シンボリックリンクで配置しました。" ;;
      *) echo "不正な選択です"; exit 1 ;;
    esac
    ;;
esac

echo ""
echo "テンプレート: $SCRIPT_DIR/templates/CLAUDE.md.template"
echo "プロジェクトルートに CLAUDE.md を配置すると効果的です。"
