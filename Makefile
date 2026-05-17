STOW_DIRS = bash claude git hypr opencode quickshell readline rofi scripts swaync tmux waybar wlogout

# files or directories that might conflict with stow and should be backed up
BACKUP_TARGETS = .bashrc .claude/CLAUDE.md .claude/settings.json .claude/statusline-command.sh .config/hypr .config/hypr/host.conf .config/opencode .config/quickshell .config/rofi .config/swaync .config/waybar .config/wlogout .gitconfig .inputrc .tmux.conf

# gnupg requires a real directory with strict permissions, so stow's directory
# folding cannot be used. Symlink individual config files instead.
GNUPG_FILES = gpg-agent.conf

all: stow

stow:
	@for f in $(BACKUP_TARGETS); do \
		if [ -e $$HOME/$$f ] && [ ! -L $$HOME/$$f ]; then \
			echo "Backing up existing $$f to $$f.bak"; \
			mv $$HOME/$$f $$HOME/$$f.bak; \
		fi; \
	done
	stow --verbose --target=$$HOME --restow $(STOW_DIRS)
	@mkdir -p $$HOME/.gnupg && chmod 700 $$HOME/.gnupg
	@for f in $(GNUPG_FILES); do \
		ln -sf $$PWD/gnupg/.gnupg/$$f $$HOME/.gnupg/$$f; \
		echo "LINK: .gnupg/$$f => dotfiles/gnupg/.gnupg/$$f"; \
	done
	@$(MAKE) --no-print-directory host-link

delete:
	stow --verbose --target=$$HOME --delete $(STOW_DIRS)
	@for f in $(GNUPG_FILES); do \
		rm -f $$HOME/.gnupg/$$f; \
		echo "UNLINK: .gnupg/$$f"; \
	done
	@$(MAKE) --no-print-directory host-unlink

host-link:
	@mkdir -p $$HOME/.config/hypr
	@host=$$(hostname -s); \
	target="hosts/$$host.conf"; \
	if [ ! -e $$HOME/.config/hypr/$$target ]; then \
		echo "WARN: $$HOME/.config/hypr/$$target missing (no per-host fragment for $$host)"; \
	fi; \
	ln -sfn $$target $$HOME/.config/hypr/host.conf; \
	echo "LINK: .config/hypr/host.conf => $$target"

host-unlink:
	@rm -f $$HOME/.config/hypr/host.conf
	@echo "UNLINK: .config/hypr/host.conf"

.PHONY: all stow delete host-link host-unlink
