.PHONY: install install-all link link-fix check palette lint shellcheck syntax fmt-nvim lint-nvim verify ia ia-bench ia-model ia-ollama backup steam-disk keyd

install:
	./install.sh

install-all:
	./install.sh --all

link:
	./link.sh

link-fix:
	./link.sh --fix

check:
	./check.sh

palette:
	./scripts/generate-palette.sh

LINT_SH = install.sh link.sh check.sh scripts/*.sh scripts/lib/*.sh config/shell/path.sh config/colors/palette.sh

lint: syntax
	@command -v shellcheck >/dev/null || { \
		echo "shellcheck no está instalado. Instalalo con: sudo pacman -S shellcheck"; \
		exit 1; \
	}
	shellcheck --severity=warning $(LINT_SH)
	shellcheck -s bash --severity=warning config/.bashrc config/.zsh_aliases

# shellcheck no soporta zsh: al menos validamos sintaxis.
syntax:
	zsh -n config/.zshrc config/.zsh_aliases

shellcheck: lint
	@echo "shellcheck OK"

# Neovim / Lua
NVIM_DIR = config/nvim
STYLUA ?= $(shell command -v stylua 2>/dev/null || echo "$$HOME/.local/share/nvim/mason/bin/stylua")

fmt-nvim:
	@test -x "$(STYLUA)" || { \
		echo "stylua no está instalado (Mason: ~/.local/share/nvim/mason/bin/stylua)"; \
		exit 1; \
	}
	"$(STYLUA)" $(NVIM_DIR)

lint-nvim:
	@test -x "$(STYLUA)" || { \
		echo "stylua no está instalado (Mason: ~/.local/share/nvim/mason/bin/stylua)"; \
		exit 1; \
	}
	"$(STYLUA)" --check $(NVIM_DIR)

verify: lint lint-nvim check
	@echo "Verificación completa OK"

ia:
	./scripts/llama-check.sh

ia-bench:
	./scripts/llama-check.sh --bench

ia-model:
	@if [ -z "$(MODEL)" ]; then \
		echo "uso: make ia-model MODEL=coder|4b|9b"; \
		exit 1; \
	fi
	./scripts/llama-model.sh "$(MODEL)"

ia-ollama:
	./scripts/ollama-check.sh

steam-disk:
	@echo "Montando disco WD para Steam (requiere sudo)..." 
	sudo bash scripts/mount-steam-disk.sh

keyd:
	./install.sh --only keyd

backup:
	@backup_dir="/tmp/dotfiles-backup-$$(date +%s)" && \
	mkdir -p "$$backup_dir" && \
	cp -r config "$$backup_dir/" && \
	echo "Backup guardado en $$backup_dir"
