# Global Context

Default preferences. Project-level CLAUDE.md may override.

@context/GIT.md
@context/GITHUB.md
@context/CODING.md
@context/COMMUNICATION.md
@context/SECURITY.md
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input → knowledge graph. Trigger: `/graphify`
User types `/graphify` → invoke Skill tool with `skill: "graphify"` first.

# graphify MCP servers (cross-session knowledge)
- **graphify-personal** — corpus graph over `~/raw/` (curated notes/papers/tweets). Use `mcp__graphify-personal__*` for questions about saved knowledge artifacts ("what do I know about X", "how does X relate to Y in my notes").
- **graphify-memory** — episodic-recall graph over `~/.graphify/memory-workspace/projects/` (rsync of `~/.claude/projects/*/memory/`). Use `mcp__graphify-memory__*` for cross-session, cross-project recall: feedback/user/project/reference memories. Example: "what's my testing philosophy across all projects", "have I solved this auth pattern in another repo".
- **Auto-rebuild + push**: systemd user timer `graphify-sync.timer` runs `~/dotfiles/scripts/graphify-sync.sh` daily (Persistent=true, catches missed runs after device off). It rebuilds both graphs and pushes `~/raw` to `atqamz/raw` with per-file Gemini-generated commit messages (falls back to `claude -p` if Gemini fails). Manual run: `systemctl --user start graphify-sync.service`. Tail log: `journalctl --user -u graphify-sync.service -f`. `GEMINI_API_KEY` fetched from `pass show dotfiles/api-key/gemini` (encrypted via gpg, agent must be unlocked or pinentry will prompt).

# podman-tui wrapper
- **podman-tui** (`~/dotfiles/scripts/.local/bin/scripts/podman-tui`) - shells out to `/usr/bin/podman-tui` after exporting `CONTAINER_PASSPHRASE` from `pass show dotfiles/ssh/passphrase`. Required because podman bindings (golang ssh mode) read the encrypted identity file directly and never fall back to ssh-agent — without the env var, TUI fails with `x509: decryption password incorrect`. CLI `podman --connection ...` is unaffected (uses native ssh + agent). Seed on new machine: `pass insert dotfiles/ssh/passphrase`.