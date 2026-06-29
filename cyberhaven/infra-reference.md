# Cyberhaven Infrastructure & Production Data Reference

Read this when doing prod/dev data investigation — Spanner, BigQuery, PAM grants, GCS managed-content buckets, Groundcover, or GKE/k8s. Not needed for general coding sessions.

## Spanner

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

## BigQuery

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

## PAM (Privileged Access Manager)

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

## GCS Managed Content Buckets

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

## Groundcover

Four separate Groundcover MCP instances:

| MCP Instance | Purpose | Tool Prefix |
|---|---|---|
| `groundcover` | US production (primary, highest volume) | `mcp__groundcover__*` |
| `groundcover-australia` | Australia production | `mcp__groundcover-australia__*` |
| `groundcover-europe-west2` | Europe (west2) production | `mcp__groundcover-europe-west2__*` |
| `groundcover-dev` | Development clusters only | `mcp__groundcover-dev__*` |

**Always query all three production regions** for monitoring — an issue in AU/EU won't appear in US.

Cluster names in groundcover don't always match GKE names. Known exceptions include:
- prod-group-internal: `prod-dogfood`, `release-candidate` (env=prod-group-internal)

Useful metrics:
- `dlp_categorizer_categorizer_bytes_processed_total` — has `backend` label (gemini/slm)
- `dlp_categorizer_llm_requests_total` — has `model` label

Other metrics used in alerting are available in the Groundcover repository `~/code/groundcover`.

**For AI Classification monitoring context** (full monitor catalog, query templates, causal chains, PromQL recipes, PAM/Vertex investigation): see `~/llmout/prod-monitoring-agent/` — start with `prompt.md` for agent invocation or `index.html` for human browsing.

## GKE / K8s

Cluster projects follow `ch-prod-{suffix}` (prod) or custom names (dev). Auth is accomplished with shell function `kreds {cluster-name}`, e.g. `kreds ae1` (for prod ae1 customer). For dev, you must supply the project argument, e.g. `kreds es-scalability-test linea3` (for the `linea3` cluster).

```bash
# Useful pod patterns
# CCP workers: ccp-content-worker-*, ccp-metadata-worker-*
# CI stack: ci-processor-*, dlp-coordinator-*, dlp-categorizer-*
```

## Provenance Flow

For provenance-related work, start with `~/llmout/provenance-flow-reference.html` to understand how the flows work.
