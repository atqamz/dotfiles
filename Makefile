STOW_DIRS = bashrc bin gitconfig hypr inputrc kitty rofi swaync waybar wlogout

# files or directories that might conflict with stow and should be backed up
BACKUP_TARGETS = .bashrc .gitconfig .inputrc .config/hypr .config/kitty .config/rofi .config/swaync .config/waybar .config/wlogout

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
