# Global Rules

## Commit messages
- Never sign commits (no "Generated with Claude Code" / "Co-Authored-By").
- Prefer one- or two-line commit messages.
- Run Go linting before committing: e.g. `cd /Users/driott/code/dataflow/backend && make lint-folder path=apps/dlp-categorizer/governor 2>&1`.

## Pull Requests
Open the description with a 1–2 line high-level summary, then enough to understand the problem and solution. Avoid excessive detail — people won't read a wall of text.

Edit descriptions with this style:
`gh api repos/CyberhavenInc/dataflow/pulls/<pr_number> -X PATCH -f body='...'`

Replying to review comments — never edit an existing comment. Always reply:
- General PR comment: `gh pr comment <pr_number> --body "..."`
- Reply to a specific review comment: `gh api repos/<owner>/<repo>/pulls/<pr_number>/comments -X POST -f body="..." -f in_reply_to=<comment_id>`

## Background Tasks
For background tasks with an expected duration, report both the duration (e.g. ~25m) and the expected completion time in Mountain Time (e.g. ~12:30pm).

## Jira
Use the Jira tool scripts in `~/.config/tools/jira/` (on PATH) instead of raw `acli` commands.

### Available tools
```bash
jira-view DDR-1234                        # Full ticket details (JSON)
jira-view DDR-1234 --fields key,summary   # Specific fields only
jira-search 'project = DDR AND status = "To Do"'             # JQL search (JSON)
jira-search 'assignee = currentUser()' --limit 20 --fields key,summary,status
jira-transition DDR-1234 "In Dev"         # Transition status
jira-transition DDR-1234,DDR-1235 "In Review"  # Bulk transition
jira-assign DDR-1234                      # Assign to self
jira-assign DDR-1234 david.riott          # Assign to user
jira-assign DDR-1234 --unassign           # Remove assignee
jira-comment DDR-1234 "Comment text"      # Add comment
jira-is-epic DDR-1234                     # Exit 0 if Epic, 1 otherwise
jira-is-epic DDR-1234 --print             # Print issue type name
jira-children DDR-1234                    # List child tickets (JSON)
jira-children DDR-1234 --exclude-done     # Children minus Done/Closed (uses statusCategory)
jira-children DDR-1234 --status "To Do"   # Children with specific status
jira-reparent DDR-1234 DDR-5678           # Move ticket to a different epic
jira-reparent DDR-1234,DDR-1235 DDR-5678  # Move multiple tickets
jira-api GET /rest/api/3/issue/DDR-1234   # Raw REST API (for anything else)
jira-api PUT /rest/api/3/issue/DDR-1234 '{"fields":{...}}'
```

### Notes
- All tools that return data output JSON
- `jira-search` --fields does NOT support "updated"
- `jira-transition` may fail if the workflow doesn't allow direct transition
- `jira-api` uses the acli API token from macOS keychain (service: "acli", base64-encoded with "go-keyring-base64:" prefix)
- `acli jira workitem edit` does NOT support `--parent`; use `jira-reparent` or `jira-api` for epic reassignment
- `acli` subcommands have different flags — e.g. `assign` uses `-k`/`-a`/`-y`, `transition` uses `--key`/`--status`/`--yes`. Always check `acli jira workitem <cmd> --help` when writing new wrappers.
- For operations not covered by these tools, fall back to `jira-api` or `acli jira` directly

## Infrastructure & Production Data Access
Reference for Spanner, BigQuery, PAM grants, GCS managed-content buckets, Groundcover, and GKE/k8s lives in `~/.config/cyberhaven/infra-reference.md`. Read it before prod/dev data investigation; don't load it otherwise.

For editing Grafana dashboards (`monitoring.cyberhaven.io/grafana/d/…`) or Groundcover explore dashboards via REST API, see `~/.config/cyberhaven/groundcover-dashboards.md`.

k8s auth: I run `kreds` myself in a separate terminal and will tell you when a cluster is available — don't authenticate clusters yourself.

## Local Repository Map
- `~/code/prod-infrastructure` *(CLAUDE.md)* — Terraform for all prod GCP: ~517 `ch-prod-*/` per-customer dirs, ~34 `prod-group-*/`, plus `ch-prod-platform/` (ArgoCD, Vault), `ch-prod-analytics/`, `prod-cd/`. Ships via GitHub Actions (`terraform.yaml`). Per-customer dirs are generated from `environments-templates` — **do not edit them directly**; non-customer-specific projects (e.g. SLM Inference) may be edited directly.
- `~/code/environments-definitions` *(CLAUDE.md)* — Source of truth for env configs (~450 prod + ~50 dev + ~12 stage YAML). PRs trigger cookiecutter regeneration in `prod-infrastructure`. Owns feature flags, app versions, wave rollouts. `scripts/` = Vault ops, validation, migration.
- `~/code/environments-templates` *(CLAUDE.md)* — Cookiecutter Jinja2 templates generating per-customer Terraform from `environments-definitions`. `values/_common.yaml` = 1200+ lines of defaults. CalVer (`YY.MM`); promote dev → stage → release tag.
- `~/code/helm-charts` *(CLAUDE.md)* — 110+ Helm 3 charts (AI/ML, content inspection, cloud connectors, data pipeline, on-prem). OPA/Rego conftest enforces Ingress auth annotations. Versions auto-increment on merge.
- `~/code/charts-values` *(no CLAUDE.md)* — Helm values overrides on `helm-charts`, by `dev/ stage/ prod/prod-group-*/`. Pairs with `environments-definitions` to fully describe a deployment.
- `~/code/dev-playground` *(no CLAUDE.md)* — Shared Terraform dev/test envs (`ch-dev-*`, `ch-stage-*`) for validating infra pre-prod. **Shared space — coordinate before changing.** Includes `aws-onprem/`, `az-onprem/`.
- `~/code/dataflow` *(no CLAUDE.md)* — Core platform monorepo: `backend/` (Go API), `frontend/` (TS/React, Vite), `Sensors/` (Go agents), `services/` (microservices), `dlp-onprem/`, `k8s/`, `docker/`, `packer/`.
- `~/code/groundcover` *(no CLAUDE.md)* — Terraform/Terragrunt for Groundcover monitoring: `catalog/modules/` (monitors, silences), `live/dev|prod/`, `catalog/clusters.yaml` registry. Manage alert rules, thresholds, silences, notifications here.
- `~/code/llmops-procedures` *(CLAUDE.md at `.claude/CLAUDE.md`)* — Runbooks/automation for fine-tuning & deploying LLMs/SLMs on Vertex AI: `vertexai-slm-ft` (LoRA), `vertexai-llm-sft` (Gemini SFT). Driven by Claude Code skills.

## Local Disk Usage
Prefer HTML over Markdown for file outputs (more human-reviewable); keep it clean, not flashy. Write preserved output to `~/llmout`.
