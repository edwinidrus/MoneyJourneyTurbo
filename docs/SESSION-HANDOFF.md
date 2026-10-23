# Session handoff (2026-10-23)

Read this first on a new machine or in a new Claude Code session. Then read `docs/PLAN.md` (the approved plan), `docs/VERIFY.md` (verified Hermes facts) and `implementation/CONSTITUTION.md` (rules, including project articles VIII–IX).

Suggested opening prompt for the next session:
> Read docs/SESSION-HANDOFF.md, docs/PLAN.md, docs/VERIFY.md and implementation/CONSTITUTION.md, then continue from "Next steps".

## Where we are

| Step | State |
|---|---|
| Phase 0 discovery | done. Report is in `docs/PLAN.md` ("Technical plan" section). |
| Phase 1 (= dragonhoard M1) | partly done, see below |
| Dragonhoard init (hybrid, root `implementation/`) | done |
| Constitution articles VIII (axioms) + IX (security) | done |
| OpenCode builder install (`exa` off, `serena` on) | done |
| Builder model `opencode/deepseek-v4.1-flash-free`, fallback `opencode/glm-5.3-flash-free` | set |
| Smoke `delegate` | **FAILED: OpenCode Zen API key expired (401 `api_key_expired`)** |
| Shape milestones M1–M4 | not started |

## Owner decisions
- Cloud LLM: Ollama Cloud. Hermes primary `glm-5.3:cloud`, fallback `kimi-k3:cloud`.
- Vault: pluggable through `VAULT_PATH`. Currently `~/vault` on WSL ext4.
- No hardcoded scope: countries, series and watchlists come from `05-Domains/` notes.
- Hermes write scope lives in a separate `research` profile; the default profile is untouched.
- Removed the dangerous permanent approvals from the Hermes `command_allowlist`.
- Delivery: dragonhoard hybrid. OpenCode builds on free models; Claude orchestrates, judges and verifies, using superpowers disciplines (TDD, verification-before-completion, code review).
- Checks: none yet. Add `uv run pytest` and `uv run ruff check` when `data-worker/pyproject.toml` exists.
- Live-system changes (Hermes config, systemd, docker, `~/.hermes`) are never delegated (article 31).

## Repo contents (this session)
- `docs/PLAN.md`: approved plan (delivery process plus technical plan).
- `docs/VERIFY.md`: Hermes v0.21.3 facts, risks, applied changes.
- `vault-template/`, `scripts/vault-init.sh`: vault skeleton and idempotent init (tested).
- `dragonhoard.json`, `implementation/`, `.dragonhoard/`, `.opencode/`, `AGENTS.md`, `opencode.json`: dragonhoard scaffold. `opencode.json` additionally denies `sudo`, `docker`, `systemctl`, `hermes`, `ollama` and `crontab` for the builder.

## Machine-local state (NOT in git; recreate or copy on a new system)
| Item | Where | How to recreate |
|---|---|---|
| Hermes install v0.21.3 | `~/.hermes/hermes-agent`, `~/.local/bin/hermes` | official repo, same tag |
| `research` profile | `~/.hermes/profiles/research` | `hermes profile create research --clone --no-alias`, then append `HERMES_WRITE_SAFE_ROOT=<vault>/00-Inbox:<vault>/90-Agent` to its `.env` |
| Allowlist cleanup | `~/.hermes/config.yaml` | set `command_allowlist: []` |
| Vault | `~/vault` (git, empty skeleton) | `scripts/vault-init.sh <path>` |
| Backups | `~/backups/hermes-2026-10-23.tgz` (warm), `~/backups/hermes-config-2026-10-23.yaml` | machine-specific |
| Secrets | `~/.hermes/.env`, profile `.env`, OpenCode auth | never committed; set up again by hand |
| Dragonhoard plugin | `~/.claude/plugins/cache/dragonhoard/dragonhoard/0.3.0` | install the plugin; a repo copy is in `.dragonhoard/scripts/dragonhoard.py` |

Paths in `docs/` and `opencode.json` assume `/home/edharth91`. Adjust them on a different user or host.

## Next steps
1. Owner: create a new OpenCode Console API key, then run `opencode auth login` (OpenCode/Zen provider).
2. Rerun the smoke test:
   `python3 .dragonhoard/scripts/dragonhoard.py delegate --retries 1 "Smoke test only. Do not edit any file. Read dragonhoard.json and end with a HANDOFF block: status DONE, files none, checks none."`
3. `/dragonhoard:shape docs/PLAN.md`: propose M1 (prove the loop) through M4 (markets) as in the plan. Owner confirms the cut, then M1 packs are written. Mark the done items (backup, allowlist, profile, vault-template, vault-init, VERIFY) as done.
4. `/dragonhoard:conduct` for the M1 packs.
5. Open owner items from Phase 1:
   - `hermes gateway restart` (drops the old allowlist from memory)
   - `hermes -p research fallback add`, then pick `kimi-k3:cloud`
   - confirm the Ollama Cloud plan has a hard spending cap
   - give the first research goal in plain words (input for `domain-scout`)
   - open `\\wsl.localhost\Ubuntu-24.04\home\edharth91\vault` in Obsidian and test file watching

## Known risks
- The terminal tool bypasses `HERMES_WRITE_SAFE_ROOT`. Keep Phase 1 agent runs supervised until the Phase 3 ro mounts.
- The warm backup may have mid-write SQLite. Take a cold backup (gateway stopped) before the Phase 3 migration.
- WSL has 7.6 GiB RAM with about 10 unrelated containers running.
