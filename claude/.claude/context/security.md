# Security

- **Never commit secrets:** `.env`, API keys, tokens, passwords, private keys.
  Warn if asked to.
- **Don't echo secrets** in output or logs.
- **Sensitive file patterns:** `.env*`, `credentials.json`, `*.pem`, `*.key`,
  `id_rsa*`. Don't read unless explicitly asked with clear context.
- **Git staging:** If `git status` shows a sensitive file, warn before adding.
- **Never modify or display private key material.**
