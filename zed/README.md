# zed

Configuration for the Zed editor.

`settings.json` sets the theme, fonts, VSCode base keymap, and docks the
built-in terminal to the left as a sidebar. `keymap.json` forwards ctrl-combos
to the terminal when it is focused, so shell readline and Claude Code newline
(Ctrl+J) behave like a native terminal instead of being captured by editor
shortcuts.

Only `settings.json` and `keymap.json` are stowed; Zed's other state files in
`~/.config/zed` (database, logs) are left untouched.

## Dependencies

- zed
