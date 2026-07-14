.PHONY: install install-all palette lint shellcheck backup

install:
	./install.sh

install-all:
	./install.sh --all

palette:
	./scripts/generate-palette.sh

lint:
	shellcheck scripts/*.sh install.sh config/shell/path.sh config/colors/palette.sh

shellcheck:
	@shellcheck scripts/generate-palette.sh install.sh config/shell/path.sh config/colors/palette.sh

backup:
	@ts=$$(date +%s); \
	mkdir -p /tmp/dotfiles-backup-$$ts && \
	cp -r config /tmp/dotfiles-backup-$$ts/ && \
	echo "Backup guardado en /tmp/dotfiles-backup-$$ts"
