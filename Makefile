.PHONY: install install-all link link-fix check palette lint shellcheck backup

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

lint:
	shellcheck scripts/*.sh install.sh link.sh check.sh config/shell/path.sh config/colors/palette.sh

shellcheck:
	@shellcheck scripts/generate-palette.sh install.sh link.sh check.sh config/shell/path.sh config/colors/palette.sh

backup:
	@backup_dir="/tmp/dotfiles-backup-$$(date +%s)" && \
	mkdir -p "$$backup_dir" && \
	cp -r config "$$backup_dir/" && \
	echo "Backup guardado en $$backup_dir"
