# Hermes Research Vault: delivery plan (dragonhoard hybrid + superpowers)

## Context
The spec and the technical plan (sections below "Technical plan") were approved. Phase 1 is partly done: backup, allowlist cleanup, `research` profile, `~/vault`, and `docs/VERIFY.md`. The owner now wants the remaining work run through **dragonhoard** (milestones, task packs, gates, lessons). Building goes to **OpenCode on free models** to save Claude tokens. **Superpowers** disciplines govern the Claude side: TDD, verification and code review.

## Owner decisions (2026-10-23)
- Mode **hybrid**. OpenCode builds; this Claude Code session orchestrates, judges and verifies.
- Builder model `opencode/deepseek-v4.1-flash-free` ($0). Fallback `opencode/glm-5.3-flash-free` ($0). Both confirmed in `opencode models` (v2.1.4).
- Root `implementation/`.
- Checks: none now. Add `uv run pytest` and `uv run ruff check` inside the pack that creates `data-worker/pyproject.toml`.
- Constitution articles: design axioms A1–A5 and spec section 11 security rules.

## Facts checked
- `dragonhoard.json` is absent, so init is needed. OpenCode was upgraded by the owner to **v2.1.4**, the major version dragonhoard was tested on. `opencode models` lists `opencode/deepseek-v4.1-flash-free` and `opencode/glm-5.3-flash-free`.
- OpenCode MCP servers: `serena` (local code tools) and `exa` (web search, external). Plan: builder keeps `serena`, and `exa` goes in `--mcp-off`. A4 says the builder should not ingest web content. Owner can flip this.
- Dragonhoard has **no native model fallback**. `delegate` has `--retries` and `--quota-wait`/`--quota-patience`. Fallback procedure: after quota patience runs out, or after a second FAIL caused by the model rather than the pack, run `dragonhoard.py models --set builder=opencode/glm-5.3-flash-free --why "fallback: <reason>"` (it is logged), then switch back after the task.

## Steps

### A. Init (dragonhoard:init)
```bash
DH="python3 /home/edharth91/.claude/plugins/cache/dragonhoard/dragonhoard/0.3.0/scripts/dragonhoard.py"
$DH init --root implementation --mode hybrid
```
Append articles VIII+ to `implementation/CONSTITUTION.md`:
- VIII–XII: axioms A1–A5 (vault is truth; numbers only from code; frontmatter contract plus one note per entity; agent writes only to `00-Inbox`/`90-Agent`, web content untrusted; cloud models with caps).
- XIII: security spec 11.1–11.11, condensed: container-only Hermes after Phase 3, approvals never off or `--yolo`, two-layer write scope via `HERMES_WRITE_SAFE_ROOT` plus ro mounts, no docker.sock or privileged containers, non-root, `cap_drop`, ports on 127.0.0.1 only, secrets only in `.env` with chmod 600, provider caps, Telegram allow-list, pinned Hermes tag, backup before update, prompt-injection guard in every skill.

### B. Builder install + models
```bash
$DH install --host opencode --mcp-off exa
$DH models --set builder=opencode/deepseek-v4.1-flash-free scout=opencode/deepseek-v4.1-flash-free spiker=opencode/deepseek-v4.1-flash-free --why "owner: free models, Claude judges"
```
Then a smoke check: one trivial `delegate` round trip, to confirm OpenCode 2.1.4 and the free model return a HANDOFF block.

### C. Shape (dragonhoard:shape)
Source plan = the technical plan below, copied to `implementation/SOURCE-PLAN.md` together with `docs/VERIFY.md`. Proposed milestone cut, shown to the owner before any packs are written:
- **M1 Prove the loop.** Already done: backup, allowlist cleanup, profile, `vault-template/`, `vault-init.sh`, VERIFY (recorded as done). Remaining: fallback in Hermes, domain-scout skill, first domain note, 5 manual questions, Obsidian watch test. Gate = spec Phase 1 acceptance.
- **M2 Schema, validation, skills.** data-worker v0 (validate-note, macro), SearXNG, web-brief, macro-pull, consolidate, dashboards, promote.sh, autocommit timer, cron per domain. Gate = one weekly cycle plus one promotion.
- **M3 Containerise.** Compose, mounts, migration, healthcheck, backup, README, sidebar plugin. Gate = restart loses nothing and healthcheck is green.
- **M4 Markets.** equity snapshot, technicals, marked-block updater, equity-snapshot skill. Gate = `snapshot TSM`.

Only M1 packs are written first. Later packs are written when their milestone becomes current.

### D. Build loop (dragonhoard:conduct + superpowers)
For each pack:
1. `$DH next` hands over the task, then `$DH delegate "Use the dragonhoard-next skill."` sends it to the OpenCode builder.
2. JUDGE or QUESTION from the builder: I answer, or ask the owner. Open implementation choices go through `dragonhoard:explore`.
3. DONE: `$DH verify <task>`. Then I apply **superpowers:verification-before-completion** (run the pack's acceptance myself) and **superpowers:requesting-code-review** on the diff. Packs with logic, such as data-worker, must have been written test-first per **superpowers:test-driven-development**; verify flags weakened tests.
4. FAIL: one retry. A second FAIL means the model fallback above, or escalation to a solo build in Claude for that task.
5. Tasks that touch the live system (Hermes config, systemd, docker, the `~/.hermes` migration) are **never delegated**. Claude runs them with an owner checkpoint, because they are hard to undo.
6. Milestone end: GATE.md, review of the milestone diff, the owner plays it, then `dragonhoard:learn`.
7. Last milestone: **superpowers:finishing-a-development-branch**.

## Verification
- After A/B: `dragonhoard.json` shows `root: implementation`, `mode: hybrid` and the three roles; `opencode.json` denies git commits; a smoke `delegate` returns a HANDOFF.
- After C: the owner confirms the milestone cut; the M1 packs exist under `implementation/`.
- Per task: `verify` PASS, Claude re-runs the acceptance, and the owner checkpoint.

---
# Technical plan (approved earlier; source for shape)

## Phase 0 discovery report (2026-10-23)

| Item | Finding | Spec assumption | Impact |
|---|---|---|---|
| GPU | **Intel UHD only, no NVIDIA** | Windows GPU for Ollama | Local LLM only for embeddings/tiny models. Routing row "≤8 GB / CPU only": cloud runs agent loop. |
| Host RAM | 16 GB Windows; WSL 7.6 GiB (no `.wslconfig`, default 50%), ~3 GiB free | — | Tight with 10 other containers running. |
| CPU / disk | 12 threads; 839 GB free on ext4 | — | fine |
| WSL | 2.7.3, kernel 6.6.114, systemd=true, no `.wslconfig` (NAT networking) | — | systemd timer OK for autocommit |
| Docker | **Docker Engine native in WSL** 28.3.3, Compose v2.39.1 | Desktop or Engine | `host-gateway` = WSL VM, which is where Ollama lives anyway |
| Ollama | **Installed in WSL** (systemd), v0.34.2, bound `127.0.0.1:11434`. Models: `glm-5.3:cloud`, `deepseek-v4-pro:cloud`, `glm-5.2:cloud`, `kimi-k3:cloud`, `minimax-m2.5:cloud`, `nomic-embed-text` | Native on Windows | Container cannot reach 127.0.0.1-bound Ollama. Need `OLLAMA_HOST` bound to docker bridge IP (172.17.0.1) or 0.0.0.0 + firewall, or Hermes uses `network_mode: host`. |
| Hermes | **Already installed natively**: v0.21.3 (git, `~/.hermes/hermes-agent`), gateway running, **Telegram connected**, `allow_all_users: false`, model `glm-5.3:cloud` via provider `ollama-launch` (base_url `http://127.0.0.1:11434/v1`), `cron.catch_up_missed: true`, existing sessions/memories/skills | Phase 1 installs it | Phase 1 install step already done. Phase 3 must migrate existing `~/.hermes` (with live Telegram + state). |
| CLI | `hermes fallback`, `hermes cron`, `hermes gateway`, `--yolo` exist | — | Verify `writable_roots` key still unknown |
| Vault | No `~/vault` | — | fresh vault likely |
| Python / git | 3.12.3 / 2.43.0 | — | fine |
| Repo | `~/Hobbys/MoneyJourneyTurbo` (spec + README only) | `hermes-research-vault/` | Use this repo as project root |
| Other | 10 unrelated containers running, several on `0.0.0.0` (librechat, neo4j, :5000, :8000) | — | outside scope; note RAM pressure |

Not run: throwaway `docker run curlimages/curl` probe (pulls image). Not confirmed: `writable_roots` key, gateway HTTP port, official Docker image.

## Owner answers
1. GPU/RAM: answered by discovery (CPU-only).
2. Docker: native Engine in WSL.
3. Cloud LLM: **Ollama Cloud as-is**. Primary `glm-5.3:cloud`, fallback `kimi-k3:cloud`. Cap: whatever the Ollama plan enforces (owner to confirm the plan has a hard limit).
4. Vault: **pluggable**. Any location: WSL ext4, Windows NTFS (`/mnt/c/...`), or cloud (a synced folder such as OneDrive/Dropbox/Google Drive, or a git remote).
5–7, 9. **No hardcoded scope.** No default countries, series or watchlist. The agent derives search strategy from domain-context notes.
8. Telegram: already connected. Keep it and verify the allow-list.

## Spec deviations (from discovery and answers)
- **No `ollama/Modelfile`.** No local LLM. Cloud models set their own context. `nomic-embed-text` stays available, unused for now.
- **Phase 1 install already done.** Reuse the native Hermes after a backup.
- **Containerised Hermes talks to Ollama Cloud directly** (`ollama.com` API plus an API key), not through the WSL Ollama on 127.0.0.1. This removes the host-reachability problem. *Verify Hermes has an Ollama Cloud provider* (hint: `~/.hermes/ollama_cloud_models_cache.json` exists). Fallback if it doesn't: an Ollama systemd override with `OLLAMA_HOST=0.0.0.0` plus a firewall rule allowing only the docker bridge.
- **`VAULT_PATH` env var** replaces the hardcoded `~/vault`.
- **New note type `domain`.** Use cases become data, not code.
- Project root = this repo (`MoneyJourneyTurbo`), not `hermes-research-vault/`.

## Design addition 1: pluggable vault
- One variable, `VAULT_PATH`, in `.env`. `scripts/vault-init.sh <path>` creates the folder structure (from `vault-template/`) at any path and runs `git init` if there is no repo yet. Existing notes are never overwritten; only missing folders and templates are added.
- Compose mounts `${VAULT_PATH}:/vault:ro`, plus `${VAULT_PATH}/00-Inbox` and `${VAULT_PATH}/90-Agent` as `:rw`. The same two-layer rule applies whatever the location.
- Location notes go in the README, not in code:
  - WSL ext4: fastest. Obsidian opens it over `\\wsl.localhost`.
  - Windows `/mnt/c`: slower 9p I/O, but Obsidian file watching is reliable.
  - Cloud: point `VAULT_PATH` at a locally synced folder (OneDrive/Dropbox under `/mnt/c/Users/edwin/...`), or keep a git remote and push from the autocommit script (`VAULT_GIT_REMOTE`, optional). Obsidian Sync cannot be mounted; it works only with a local copy.
- ponytail: no rclone/WebDAV mount layer. Add one only if a vault must live with no local copy.

## Design addition 2: domain-context notes (no defaults)
- New folder `05-Domains/` with one note per research domain (e.g. "Sovereign AI in GCC", "Semis supply chain"). Frontmatter: `type: domain`, plus body sections: *Goal*, *Key actors*, *Where signals appear* (source types, portals, publications), *Query vocabulary* (terms, synonyms, local-language terms), *Regions/entities in scope*, *Exclusions*, *Cadence*.
- Bootstrap: the owner states a goal in free text. The `domain-scout` skill (a 5th skill) researches how the domain works and drafts a domain note into `90-Agent/proposed-domains/`. The owner edits and promotes it. The human gate is unchanged.
- `web-brief`, `macro-pull`, `equity-snapshot` and `consolidate` all take `domain: [[...]]` as input. Queries, series and watchlists are read from the domain note, or from instrument notes linked to it. Nothing is hardcoded in skills or `.env`.
- Cron jobs are created per promoted domain note, at the cadence the note states.
- Consolidate also proposes edits to domain notes (new actors, better query terms) based on what the week's search returned. This is how search skill compounds.

## Phased plan

### Phase 0: done (this report)

### Phase 1: prove the loop by hand (reuse native Hermes)
1. Back up: `tar` of `~/.hermes` to `~/backups/hermes-<date>.tgz`. Verify the archive lists cleanly.
2. Verify against docs and `--help` (no guessing): the write-restriction key (`writable_roots` or equivalent) in the file toolset; SKILL.md format for v0.21; `hermes cron` syntax and TZ; `hermes fallback` usage; the Ollama Cloud provider; the approval mode; and whether v0.21 skill/memory write approvals cover `90-Agent`. Write any unconfirmed item into `docs/VERIFY.md`.
3. `hermes fallback` adds `kimi-k3:cloud`. Confirm approvals are "smart" or stricter. Check Telegram allowed-users is set (key present in `~/.hermes/.env`, value not printed).
4. Repo: `vault-template/` (folders + `_templates/` incl. `domain.md`) and `scripts/vault-init.sh`. Owner picks `VAULT_PATH`, then run init.
5. Restrict Hermes writable roots to `$VAULT_PATH/00-Inbox` and `$VAULT_PATH/90-Agent`.
6. The owner states a first domain goal. Run domain-scout by hand. Promote the domain note. Run 5 research questions by hand and log tool-loop failures in `90-Agent/logs/phase1.md`.
7. Test Obsidian file-change detection at the chosen vault location.
- **Accept:** one domain note promoted; one APAC/ME tender source note in `00-Inbox/sources/` with valid frontmatter; a write attempt outside allowed paths is refused.

### Phase 2: schema, validation, skills
- `data-worker/` (FastAPI, pyproject, Python 3.12). Endpoints: `/validate-note` (frontmatter contract incl. `type: domain`), `/macro/pull`, `/macro/summary`. Request bodies carry the series list, so no defaults sit in code. Sources: FRED (key), ECB, World Bank. DuckDB/Parquet in `./data`. Pytest with recorded fixtures and no network, including the "brief numbers == Parquet" test.
- Runs natively via `uv run` during Phase 2. Containerised in Phase 3.
- Skills in `hermes/skills/`: `domain-scout`, `web-brief`, `macro-pull`, `consolidate`. Each includes the section 11.11 prompt-injection guard, calls `/validate-note` before saving, and routes failures to `00-Inbox/_rejected/`.
- SearXNG needed now for `web-brief`. Run it alone with `docker compose up searxng`, bound to `127.0.0.1` only, JSON format on and a modest engine list. Native Hermes reaches it on localhost.
- Dataview dashboards in `vault-template/90-Agent/dashboards/`. `scripts/promote.sh` runs as the owner.
- `scripts/vault-autocommit.sh` plus a systemd user timer (15 min). Optional push to `VAULT_GIT_REMOTE`.
- Cron per promoted domain, `TZ=Europe/Berlin`.
- **Accept:** one weekly cycle (sweep, daily briefs, Sunday review) plus one owner promotion.

### Phase 3: containerise
- `docker-compose.yml` with hermes-agent (official image if one exists, otherwise build from a pinned tag), searxng and data-worker. Internal network. Only the Hermes gateway is published, on `127.0.0.1:<verified port>`. `user: 1000:1000`, `cap_drop: [ALL]`, `no-new-privileges`, no docker socket, `TZ=Europe/Berlin`, named volume `hermes-home`.
- Hermes model goes direct to Ollama Cloud (after verification), with no host Ollama dependency.
- Migrate: stop the native gateway, copy `~/.hermes` into the volume, start the container, check that Telegram, sessions and memory survive. Then remove the native install (`~/.hermes/hermes-agent` plus `~/.local/bin/hermes`) and disable its systemd/autostart.
- `.env.example`, `.env` with `chmod 600`, `.gitignore` covering `.env` and `data/`.
- `scripts/healthcheck.sh` and `scripts/backup.sh`. README runbook.
- Connect the Obsidian sidebar plugin. Review it first (third-party) and list it in the README.
- **Accept:** `down && up -d` loses nothing; healthcheck green; sidebar chat works.

### Phase 4: markets
- `/equity/snapshot`: yfinance behind a provider interface (`EQUITY_PROVIDER`). SMA/RSI/MACD written directly (no pandas-ta dependency) and tested against reference values. 52-week range and relative strength vs the benchmark named in the instrument or domain note. The marked-block updater writes `20-Entities/instruments/` (the data-worker needs that one rw mount).
- `equity-snapshot` skill. The watchlist comes from instrument notes linked to a domain note, not from config.
- **Accept:** `snapshot TSM` updates the numbers block and adds a narrative note; technicals tests pass.

## Critical files (to create)
`docker-compose.yml`, `.env.example`, `hermes/skills/{domain-scout,web-brief,macro-pull,consolidate,equity-snapshot}/SKILL.md`, `hermes/config.yaml.example`, `searxng/settings.yml`, `data-worker/src/data_worker/{api,store,render}.py` + `sources/` + `compute/`, `vault-template/` (incl. `05-Domains/`, `_templates/domain.md`), `scripts/{vault-init,vault-autocommit,promote,healthcheck,backup}.sh`, `docs/VERIFY.md`.

## Verification
- Per phase: run its acceptance criteria literally.
- `pytest data-worker/tests` (offline fixtures).
- `scripts/healthcheck.sh`: Hermes gateway on 127.0.0.1, searxng/data-worker reachable only inside the network (`ss -ltn` shows no 0.0.0.0 for our services), Ollama Cloud reachable from the Hermes container, vault mount is ro except the two rw paths (attempt `touch /vault/10-Sources/x` inside the container; it must fail).
- Restart test: `docker compose down && up -d`, then compare session count and memory files before and after.

## Risks
- WSL RAM: 7.6 GiB with 10 other containers already running. Suggest a `.wslconfig` `memory=10GB` (owner decision; it is a system config change).
- WSL idle shutdown stops cron. `catch_up_missed: true` is already set, so runs catch up at login.
- Ollama Cloud spend cap depends on the plan. Owner to confirm.
