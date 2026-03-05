.PHONY: install-xcode install-cli install-project install-link list help

help: ## ヘルプを表示
	@echo "XcodeMCP-Skills"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-20s %s\n", $$1, $$2}'

install-xcode: ## Xcode 内 Claude Agent にスキルを配置
	@bash install.sh --xcode

install-cli: ## Claude Code CLI のグローバルスキルに配置
	@bash install.sh --cli

install-project: ## 現在のプロジェクトの .claude/skills/ に配置
	@bash install.sh --project

install-link: ## シンボリックリンクで配置（推奨・自動更新対応）
	@bash install.sh --link

list: ## 利用可能なスキル一覧を表示
	@echo "=== XcodeMCP-Skills ==="
	@for d in skills/*/; do \
		name=$$(basename "$$d"); \
		desc=$$(grep '^description:' "$$d/SKILL.md" | sed 's/^description: //'); \
		printf "  %-20s %s\n" "$$name" "$$desc"; \
	done
