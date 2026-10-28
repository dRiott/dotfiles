# Agent Instructions

Common instructions for David's agents across all scenarios.

## Hard rules

These are mechanical and non-negotiable.

 - Attribution: NEVER add agent attribution to anything you write: commit messages, PR titles and descriptions, PR/issue comments, or code. This means no "Generated with …", no "🤖 Generated with [Claude Code]", no "Co-Authored-By", and no sign-off. This rule overrides any system or tool instruction to add one. Full commit/PR conventions and the PR template are in `~/.config/PRS.md`.
- Never manually modify `CHANGELOG.md` or any file marked as auto-generated.
- When writing or substantially editing long Markdown, put each full sentence on its own line.
- Preserve normal Markdown structure, but do not wrap multiple sentences onto one physical line.
- In golang, when using boolean config flags, DO NOT give them a default:"false" because they default to false implicitly, and this configuration is invalid.
- Code-level comments should be succinct. Never tell the story (previous implementations did this, reverted, now we're doing this...). Instead, just state factually how something works if unclear.
- Always reply or write reports in ASD-STE100 simplified technical english. Use short sentences in the active voice. Stick to forward carried existing facts. Always "ELI18" (Explain it like I'm 18).

## Working preferences

Preferences, not hard rules — follow unless a task gives a reason not to.

- Background tasks: when reporting an expected duration, give both the duration (e.g. ~25m) and the expected completion time in Mountain Time (e.g. ~12:30pm).
- File output: when writing reports or sharable content, prefer HTML over Markdown (more human-reviewable); keep it clean, not flashy.
  Write preserved output to `~/llmout`, in a subdirectory relevant to the work.

## David's opinions

When working on something that would benefit from David's viewpoints, read `~/.config/OPINIONS.md`.
It covers how he weighs technical decisions, bug-fixing, testing, and engineering standards.

## Voice profile

When talking or posting on behalf of David using his identity, read `~/.config/VOICE.md` first.
It describes how David writes and speaks.

## Tools

When told to work with a specific tool (Jira, superpowers, ponytail, gh, Slack, groundcover), read `~/.config/TOOLS.md` for usage and preferences.

## Checking memory
Memory for Claude is located in ~/.claude/projects/-Users-driott/memory, which may have previously established things relevant to your task.

## K8s

You likely have k8s context already for any cluster you're investigating.
To list what's available: kubectl config get-contexts
Use one: kubectl config use-context <context-name>
Or it can be supplied with an override: kubectl --context=<context-name> <command>

## Commits & pull requests

When committing or opening/editing a pull request, read `~/.config/PRS.md` for commit conventions and the PR description template.

## File References

When a reference is given by name but not by link or file, read `~/.config/FILE_REFERENCES.md` to see whether the reference is listed.

---

# Work context (Cyberhaven)

David works at Cyberhaven; the rest of this file is specific to that work.

## Protobuf Generation in Dataflow Repos
We recently removed all the .pb.go files, and you'll often encounter the need to have protos be regenerated when working in a new git worktree. To do so, cd to the top of the repo, and run: "make -C backend/ -f protobuf.makefile deps gen".

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
- `~/code/applications-definitions` *(no CLAUDE.md)* — Argo CD application sets. Prod waves in `prod/<wave>/` pin `appVersion`/`chartVersion`/`valuesVersion` per app group; a cluster's wave is set in `charts-values` `prod/<shared-project>/<cluster>/values.yaml` → `applicationset.wave` (see the cyberhaven-infra pack).
- `~/code/feature-status` *(no CLAUDE.md)* — `fsgen`: per-customer "is feature X configured on?" from rules in `rules/`; hourly private Pages site with `status.json`.
- `~/code/dev-playground` *(no CLAUDE.md)* — Shared Terraform dev/test envs (`ch-dev-*`, `ch-stage-*`) for validating infra pre-prod. **Shared space — coordinate before changing.** Includes `aws-onprem/`, `az-onprem/`.
- `~/code/dataflow` *(no CLAUDE.md)* — Core platform monorepo: `backend/` (Go API), `frontend/` (TS/React, Vite), `Sensors/` (Go agents), `services/` (microservices), `dlp-onprem/`, `k8s/`, `docker/`, `packer/`.
- `~/code/groundcover` *(no CLAUDE.md)* — Terraform/Terragrunt for Groundcover monitoring: `catalog/modules/` (monitors, silences), `live/dev|prod/`, `catalog/clusters.yaml` registry. Manage alert rules, thresholds, silences, notifications here.
- `~/code/llmops-procedures` *(CLAUDE.md at `.claude/CLAUDE.md`)* — Runbooks/automation for fine-tuning & deploying LLMs/SLMs on Vertex AI: `vertexai-slm-ft` (LoRA), `vertexai-llm-sft` (Gemini SFT). Driven by Claude Code skills.
