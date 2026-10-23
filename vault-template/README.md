# Vault conventions

| Folder | Holds | Who writes |
|---|---|---|
| `00-Inbox/` | Agent output: `sources/`, `briefs/`, `_rejected/` (failed validation) | Hermes, owner |
| `05-Domains/` | One note per research domain: goal, actors, where signals appear, query vocabulary, scope | owner (promoted from `90-Agent/proposed-domains/`) |
| `10-Sources/` | Promoted clippings, one per URL or document | owner |
| `20-Entities/` | `companies/`, `countries/`, `instruments/`, `themes/`, one note per entity | owner; data-worker only between `numbers` markers |
| `30-Briefs/` | Promoted or archived briefs | owner |
| `40-Theses/` | Living opinions | owner |
| `90-Agent/` | Reviews, logs, dashboards, proposals | Hermes, owner |
| `_templates/` | Templater templates | owner |

## Rules
- Every note has the frontmatter contract (`type`, `title`, `date`, `status`, `region`, `sector`, `entities`, `instruments`, `source_url`, `confidence`, `written_by`). `type: source` needs non-empty `entities` and a `source_url`.
- `type` is one of: `source`, `entity`, `brief`, `thesis`, `review`, `domain`.
- One note per entity. Link with `[[wikilinks]]`.
- The agent never writes outside `00-Inbox/` and `90-Agent/`. The owner promotes notes.
- There are no built-in scope defaults. Countries, series, queries and watchlists live in `05-Domains/` notes.
- In instrument notes, text between `<!-- numbers:start -->` and `<!-- numbers:end -->` is owned by the data-worker. Don't edit it.
