STOW_DIRS = bash claude git gnupg hypr kitty opencode readline rofi scripts swaync tmux waybar wlogout

# files or directories that might conflict with stow and should be backed up
BACKUP_TARGETS = .bashrc .claude/CLAUDE.md .claude/settings.json .claude/statusline-command.sh .config/hypr .config/kitty .config/opencode .config/rofi .config/swaync .config/waybar .config/wlogout .gitconfig .gnupg .inputrc .tmux.conf

all: stow

stow:
	@for f in $(BACKUP_TARGETS); do \
		if [ -e $$HOME/$$f ] && [ ! -L $$HOME/$$f ]; then \
			echo "Backing up existing $$f to $$f.bak"; \
			mv $$HOME/$$f $$HOME/$$f.bak; \
		fi; \
	done
	stow --verbose --target=$$HOME --restow $(STOW_DIRS)

delete:
	stow --verbose --target=$$HOME --delete $(STOW_DIRS)

.PHONY: all stow delete
