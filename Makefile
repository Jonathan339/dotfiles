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
	@mkdir -p /tmp/dotfiles-backup-$$(date +%s) && \
	cp -r config /tmp/dotfiles-backup-$$(date +%s)/ && \
	echo "Backup guardado en /tmp/dotfiles-backup-$$(date +%s)"
