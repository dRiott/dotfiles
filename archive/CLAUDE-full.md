# Global Rules

## Commit messages
Never sign commits yourself (Generated with [Claude Code] ... & Co-Authored-By..).
Prefer short (ideally one- or two-line) commit messages.
Always run linting for golang before committing.

## Pull Requests
When creating Pull Requests, include all the details necessary to understand the problem and the solution. At the top of the description, include a one- or two-liner explaining the changes at the highest level for the ease of a quick glance understanding. Try not to include _excessive_ detail; do not be too verbose - people won't read too much text.

When editing PR descriptions, you must use this style gh command: gh api repos/CyberhavenInc/dataflow/pulls/27043 -X PATCH -f body='{blah blah}'

When responding to PR review comments:
- NEVER edit existing comments using `gh api repos/.../pulls/comments/{comment_id} -X POST`
- ALWAYS reply to comments by posting a new comment that references the original
- Use `gh pr comment {pr_number} --body "..."` to add a general PR comment, or
- Use `gh api repos/{owner}/{repo}/pulls/{pull_number}/comments -X POST -f body="..." -f in_reply_to={comment_id}` to reply to a specific review comment

## Background Tasks
When launching background tasks that have an expected duration, report the time in MST that you expect results to come back to me, so that I not only know how long they're expected to take, e.g. ~25m, but I also know to expect them at ~12:30pm MST.

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

## Cyberhaven Infrastructure Quick Reference

### Spanner

Two Spanner instances per shared project — one for the main platform, one for CCP (Cloud Connectors Platform):

| | Main | CCP |
|---|---|---|
| **Instance** | `spanner-main-instance` | `cloud-connectors-platform` |
| **Key tables** | `location`, `content_scan`, `content_scan_rule`, `content_scanner` | `connectors`, `discovery_tracker`, `tasks` |

**Prod environments** use shared project e.g. `prod-group-3` (expect the specific prod group to be provided). Database name is derived from GKE cluster project with `ch_` prefix: `ch-prod-ae1` → `ch_ae1_database`, `ch-prod-uw2` → `ch_uw2_database`, etc.

**Dev environments** use shared project `cyberhaven-dev-group`. Database name has **no** `ch_` prefix: e.g. `linea3` cluster → `linea3_database`.

**prod-group-internal** is a special case — shared project is `prod-group-internal`, databases also have **no** `ch_` prefix: `dogfood_database`, `rc_database`. Customer GCP projects: `dogfood-275714` (dogfood), `cyberhaven-release-candidate` (RC).

```bash
# Prod example (ae1)
gcloud spanner databases execute-sql ch_ae1_database \
  --instance=spanner-main-instance --project=prod-group-3 --sql="..."

# Prod CCP example (ae1)
gcloud spanner databases execute-sql ch_ae1_database \
  --instance=cloud-connectors-platform --project=prod-group-3 --sql="..."

# Dev example (es-scalability-test)
gcloud spanner databases execute-sql es_scalability_test_database \
  --instance=spanner-main-instance --project=cyberhaven-dev-group --sql="..."
```

**Spanner query tips**: Large cross-table joins (e.g. `content_scan` JOIN `location`) often time out at 600s. Use scalar subqueries or query tables separately and join in the shell/script.

### BigQuery

Dataset naming follows the same cluster-derived pattern. Table `location_versions` is the main one powering the Datastores/Explorer UI.

```bash
# Prod example (ae1)
bq query --project_id=prod-group-3 --use_legacy_sql=false \
  "SELECT ... FROM ch_ae1_dataset.location_versions WHERE ..."

# Dev example
bq query --project_id=cyberhaven-dev-group --use_legacy_sql=false \
  "SELECT ... FROM es_scalability_test_dataset.location_versions WHERE ..."
```

`location_versions` key columns: `id`, `updated_at` (partition key, DAY), `write_id` (INVERTED — lower = newer; ascending order = newest first), `content_sha256_hash`, `content_inspected`, `labels`.

**BQ query tips**: The `labels` column is `ARRAY<STRUCT<label_set_id STRING, id STRING, version STRING>>`. Use `EXISTS(SELECT 1 FROM UNNEST(labels) l WHERE l.label_set_id = 'data/type')` — not `LIKE`.

### PAM (Privileged Access Manager)

Prod shared projects require PAM grants for data access. Grants are auto-approved and last 1 hour.

```bash
# List available entitlements
gcloud beta pam entitlements search --caller-access-type=grant-requester \
  --location=global --project=prod-group-2 --format=json

# Request a grant (1 hour max)
gcloud beta pam grants create --entitlement=data-readers-entitlement \
  --requested-duration=3600s --justification="Reason here" \
  --location=global --project=prod-group-2

# Request Vertex AI access
gcloud beta pam grants create --entitlement=vertex-ai-user-entitlement \
  --requested-duration=3600s --justification="Reason here" \
  --location=global --project=prod-group-2
```

Available entitlements (same across prod-group-3 and prod-group-4):
- `data-readers-entitlement` → `CyberhavenDataReader` role (read-only Spanner, BigQuery, GCS, Bigtable)
- `data-admins-entitlement` → `CyberhavenDataAdmins` role
- `vertex-ai-user-entitlement` → `aiplatform.user` role

Always request a PAM grant before querying prod Spanner/BQ, and expect 30s delay before PAM becomes active.

### GCS Managed Content Buckets

Per-customer buckets live in the **customer's own GCP project** (not the shared project). Naming: `{cluster}-cyberhaven-managed-content-bucket`.

```bash
# Examples
gs://dogfood-cyberhaven-managed-content-bucket/    # in dogfood-275714
gs://rc-cyberhaven-managed-content-bucket/          # in cyberhaven-release-candidate
gs://linea3-cyberhaven-managed-content-bucket/      # in es-scalability-test
```

Key subdirectories:
- `content-ai-summary/{sha}.categorizer.ai-summary.md` — AI-generated document summaries
- `results/data-type/{sha}.categorizer.slm.results.json` — SLM shadow/secondary results
- `reasoning/data-type/{sha}.categorizer.data-type-reasoning.json` — classification reasoning
- `reasoning/data-provenance/{sha}.categorizer.data-provenance-reasoning.json` — provenance reasoning

### Groundcover

There are _two_ separate groundcover MCPs: groundcover-dev for development clusters, and groundcover for production clusters.

Cluster names in groundcover don't always match GKE names. Known exceptions include:
- prod-group-internal: `prod-dogfood`, `release-candidate` (env=prod-group-internal)

Useful metrics:
- `dlp_categorizer_categorizer_bytes_processed_total` — has `backend` label (gemini/slm)
- `dlp_categorizer_llm_requests_total` — has `model` label

Other metrics used in alerting are available in Groundcover repository ~/code/groundcover.

### GKE / K8s

Cluster projects follow `ch-prod-{suffix}` (prod) or custom names (dev). Auth is accomplished with shell function `kreds {cluster-name}`, e.g. `kreds ae1` (for prod ae1 customer). For dev, you must supply the project argument, e.g. `kreds es-scalability-test linea3` (for the `linea3` cluster). Because I might be working with k8s/k9s in another terminal, I prefer to accomplish the k8s auth separately, and tell you it's avaialble.

```bash
# Useful pod patterns
# CCP workers: ccp-content-worker-*, ccp-metadata-worker-*
# CI stack: ci-processor-*, dlp-coordinator-*, dlp-categorizer-*
```

---

## Local Repository Map

### Infrastructure & Deployment

**`~/code/prod-infrastructure`** *(has CLAUDE.md)*
Terraform workspaces for all production GCP resources. ~517 `ch-prod-*/` per-customer directories (GKE, VPC, Spanner, BigTable, BigQuery, KMS, IAM), ~34 `prod-group-*/`
regional shared groups, plus `ch-prod-platform/` (ArgoCD, Vault), `ch-prod-analytics/`, and `prod-cd/` (artifact registry). Changes go through GitHub Actions
(`terraform.yaml`). For individual customers, repo is purely the outcome of template changes in `environments-templates` + regeneration. Do not make direct per-customer edits. Non-specific customer projects, for example those that house SLM Inference, can have edits made to this repo.

**`~/code/environments-definitions`** *(has CLAUDE.md)*
Source of truth for all environment configs (~450 prod + ~50 dev + ~12 stage YAML files). PR changes here trigger cookiecutter regeneration in `prod-infrastructure`.
Manages feature flags (`ai_anomaly_detection`, `dspm`, `ci_stack`), app versions, and wave rollout assignments. `scripts/` has Vault ops, validation, and migration
utilities.

**`~/code/environments-templates`** *(has CLAUDE.md)*
Cookiecutter Jinja2 templates (57 `.tf` files) that generate per-customer Terraform workspaces from `environments-definitions` configs. `values/_common.yaml` holds 1200+
lines of defaults (provider/chart versions, feature gates). CalVer releases (`YY.MM`), promotion path: dev → stage → release tag.

**`~/code/helm-charts`** *(has CLAUDE.md)*
Monorepo of 110+ Helm 3 charts for the Cyberhaven SaaS platform. Key chart groups: AI/ML (`dlp-categorizer`, `ai-analyst`), content inspection (`dlp-ocr`, `edm-scanner`),
cloud connectors (`ccp-worker`), data pipeline (`ci-processor`, `spanner-migrations`), on-prem bundles (`ci-stack-onprem`). OPA/Rego conftest policies enforce auth
annotations on all Ingress resources. Chart versions auto-increment on merge.

**`~/code/charts-values`** *(no CLAUDE.md)*
Helm values overrides layered on top of `helm-charts` defaults, organized by `dev/`, `stage/`, `prod/prod-group-*/`. ~30 regional prod groups (internal, EU, AU, JP, CA,
etc.). Works in concert with `environments-definitions` — the two repos together fully describe a customer deployment.

**`~/code/dev-playground`** *(no CLAUDE.md)*
Shared Terraform dev/test environments (`ch-dev-*`, `ch-stage-*`) for validating infra changes before production. Imports modules from `terraform-google-dataflow`.
Multi-developer shared space — coordinate before making changes. Includes `aws-onprem/` and `az-onprem/` for on-prem testing.

### Platform & Application Code

**`~/code/dataflow`** *(no CLAUDE.md)*
Core Cyberhaven platform monorepo. Key components: `backend/` (Go API), `frontend/` (TypeScript/React, Vite), `Sensors/` (Go data collection agents), `services/`
(microservices: user-management, workflow-studio, detectlang, fullstory-proxy, splunk-app, superset), `dlp-onprem/` (on-prem DLP config), `k8s/`, `docker/`, `packer/`.


### Observability

**`~/code/groundcover`** *(no CLAUDE.md)*
Terraform/Terragrunt IaC for Groundcover monitoring config. `catalog/modules/` has reusable modules for monitors and silences; `live/dev/` and `live/prod/` are the deployed
 environments; `catalog/clusters.yaml` is the cluster registry. Work here = manage alert rules, thresholds, silences, and notification policies.

### ML / LLMOps

**`~/code/llmops-procedures`** *(has CLAUDE.md at `.claude/CLAUDE.md`)*
Standardized runbooks and automation for fine-tuning and deploying LLMs/SLMs on Vertex AI. Two main procedures: `vertexai-slm-ft` (LoRA fine-tuning for small models) and
`vertexai-llm-sft` (Gemini SFT). Driven by Claude Code skills (`.claude/skills/`). Manages model versioning, multi-task adapter bundling, and Vertex AI endpoint
deployments.

## Local Disc Usage

Prefer file outputs in HTML over markdown, but do not be overly flashy or fancy unnecessarily. Use of HTML means we can write output that's more easily reviewable by humans, rather than large test markdown files that are harder to read. Directory ~/llmout is a high-level bucket for all output that is preserved for later: prefer this directory when asked to write to disk.

## Specific Flows and Investigation Details

For provenance related work, see ~/llmout/provenance-flow-reference.html to get started on how the flows work.
