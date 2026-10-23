# Verification log

Checked against installed Hermes Agent **v0.21.3** (upstream `17b5df02`, source in `~/.hermes/hermes-agent`) on 2026-10-23.
Re-check after every Hermes update.

## Confirmed

| Spec item | Actual | Source |
|---|---|---|
| `writable_roots` (section 8, layer 2) | **Not a Hermes key.** Use env var `HERMES_WRITE_SAFE_ROOT`, an `os.pathsep` (`:`) separated list of directories. | `agent/file_safety.py:get_safe_write_roots` |
| Layer-2 coverage | Enforced by the file tools (`tools/file_operations.py`) and TTS only. **The terminal tool does not check it.** A shell `echo > file` bypasses it. The real gate is layer 1 (ro bind mount, Phase 3) plus terminal approvals. | grep of `is_write_denied` callers |
| Approval modes | `manual` \| `smart` \| `off`. Key `approvals.mode`. Default `manual` (stricter than smart). Not set in current `config.yaml`, so `manual` applies. | `hermes_cli/approval_mode.py`, `tools/approval_context.py:_get_approval_mode` |
| Ollama Cloud provider | `provider: ollama-cloud`, env `OLLAMA_API_KEY` (present in `~/.hermes/.env`), base URL `https://ollama.com/v1` | `plugins/model-providers/ollama-cloud/__init__.py` |
| Fallback | `hermes fallback add` (interactive picker) writes `fallback_providers:` in `config.yaml`. Currently empty. | `hermes fallback --help` |
| Gateway HTTP port | API server default **8642**. Env `API_SERVER_PORT`, `API_SERVER_HOST`, `API_SERVER_KEY`. | `gateway/platforms/api_server.py` |
| Cron | `hermes cron create [--skill S] [--workdir D] [--model M] [--deliver T] '<cron expr>' '<prompt>'`. `cron.catch_up_missed: true` already set. | `hermes cron create --help` |
| Timezone | Config key `timezone` (empty = server-local, here Europe/Berlin) or env `HERMES_TIMEZONE`. Set it explicitly in the container. | `hermes_cli/config.py` |
| SKILL.md format | YAML frontmatter, required `name` and `description`. Optional `version`, `author`, `license`, `platforms`, `metadata.hermes.tags/related_skills`. Markdown body. | `tools/skill_manager_tool.py`, bundled `skills/research/arxiv/SKILL.md` |
| Telegram allow-list | `TELEGRAM_ALLOWED_USERS` set (1 entry). `gateway.allow_all_users: false`. | `~/.hermes/.env` (key names only), `config.yaml` |
| Docker image | **No official registry image.** The repo ships `Dockerfile` + `docker-compose.yml` (`image: hermes-agent`, built locally). Build from a pinned tag. | `~/.hermes/hermes-agent/` |

## Risks found

1. **`command_allowlist` in `~/.hermes/config.yaml` permanently pre-approves `recursive delete` and `script execution via -e/-c flag`.** The agent can `rm -rf` (including the vault) or run `python -c` without prompting. This undercuts spec 11.2 and A4. Recommendation: remove both entries before the agent gets vault access. Owner decision.
2. The terminal tool bypasses `HERMES_WRITE_SAFE_ROOT` (see above). In Phase 1 (native) the only hard guard for terminal writes is approvals. Keep Phase 1 runs supervised; Phase 3 container mounts close the gap.
3. `~/backups/hermes-2026-10-23.tgz` was taken with the gateway running (SQLite WAL may be mid-write). Take a cold backup with the gateway stopped before the Phase 3 migration.

## Applied (Phase 1, 2026-10-23)

- Backups: `~/backups/hermes-2026-10-23.tgz` (warm), `~/backups/hermes-config-2026-10-23.yaml`.
- Removed `recursive delete` and `script execution via -e/-c flag` from `command_allowlist` in the default profile. The running gateway may hold the old set until it restarts.
- Created profile `research` (`~/.hermes/profiles/research`, cloned from default, no messaging channels). Its `.env` sets `HERMES_WRITE_SAFE_ROOT=~/vault/00-Inbox:~/vault/90-Agent`. The default profile is unrestricted.
- Vault initialised at `~/vault` (git).
- **Test passed:** `hermes -p research -t file -z ...`. Write to `10-Sources/` was denied ("outside HERMES_WRITE_SAFE_ROOT"); write to `00-Inbox/` succeeded.

## Not yet confirmed

- Whether v0.21 skill/memory write approvals (spec 13) prompt for `90-Agent` writes made by the file tool.
- Obsidian sidebar plugin config keys (third-party, review in Phase 3).
- Whether the repo `Dockerfile` runs as non-root and works with `cap_drop: [ALL]`.
