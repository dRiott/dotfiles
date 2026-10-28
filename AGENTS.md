# Agent Instructions

Common instructions for David's agents across all scenarios.

## Hard rules

These are mechanical and non-negotiable.

- Commit messages: NEVER auto-add the agent name as a co-author or sign-off (no "Generated with", no "Co-Authored-By").
- Never manually modify `CHANGELOG.md` or any file marked as auto-generated.
- When writing or substantially editing long Markdown, put each full sentence on its own line.
  Preserve normal Markdown structure, but do not wrap multiple sentences onto one physical line.

## Working preferences

Preferences, not hard rules — follow unless a task gives a reason not to.

- Commit messages: prefer one or two lines.
- Background tasks: when reporting an expected duration, give both the duration (e.g. ~25m) and the expected completion time in Mountain Time (e.g. ~12:30pm).
- File output: when writing reports or sharable content, prefer HTML over Markdown (more human-reviewable); keep it clean, not flashy.
  Write preserved output to `~/llmout`, in a subdirectory relevant to the work.

## David's opinions

When working on something that would benefit from David's viewpoints, read `~/OPINIONS.md`.
It covers how he weighs technical decisions, bug-fixing, testing, and engineering standards.

## Voice profile

When talking or posting on behalf of David using his identity, read `~/VOICE.md` first.
It describes how David writes and speaks.

## Tools

When working with a specific tool (Jira, superpowers, ponytail, lavish-axi, gh), read `~/TOOLS.md` for usage and preferences.

---

# Work context (Cyberhaven)

David works at Cyberhaven; the rest of this file is specific to that work.

## Commit messages
- Run Go linting before committing: e.g. `cd /Users/driott/code/dataflow/backend && make lint-folder path=apps/dlp-categorizer/governor 2>&1`.

## Pull Requests
Open the description with a 1–2 line high-level summary, then enough to understand the problem and solution. Avoid excessive detail — people won't read a wall of text.

Edit descriptions with this style:
`gh api repos/CyberhavenInc/dataflow/pulls/<pr_number> -X PATCH -f body='...'`

Replying to review comments — never edit an existing comment. Always reply:
- General PR comment: `gh pr comment <pr_number> --body "..."`
- Reply to a specific review comment: `gh api repos/<owner>/<repo>/pulls/<pr_number>/comments -X POST -f body="..." -f in_reply_to=<comment_id>`

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
