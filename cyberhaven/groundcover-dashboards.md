# Groundcover / Grafana Dashboard Editing Reference

Read this when editing dashboards. Two separate systems exist.

## The two dashboards we actively maintain

Both are Grafana dashboards at `monitoring.cyberhaven.io`:

| Dashboard | URL | UID |
|---|---|---|
| SLM Prod Rollout | `monitoring.cyberhaven.io/grafana/d/slm-inference/slm-prod-rollout-e28094-gke` | `slm-inference` |
| DLP Categorizer | `monitoring.cyberhaven.io/grafana/d/dlp-categorizer-unified-2/dlp-categorizer` | `dlp-categorizer-unified-2` |

Local snapshots (may be outdated): `~/code/groundcover/grafana_dashboards/` and `~/code/groundcover/dashboards/`

---

## Grafana dashboards — editing workflow

**No programmatic access is possible.** `monitoring.cyberhaven.io` is a Groundcover React SPA frontend; the actual Grafana server is internal-only and not exposed externally. Attempted approaches that don't work:
- Grafana service account tokens (`glsa_...`) — blocked by OAuth proxy (401)
- `_oauth2_proxy` session cookies — pass the proxy but hit the SPA, not the Grafana API
- Groundcover REST API — only covers Groundcover explore dashboards, not Grafana

Dashboard editing goes through the UI only.

### Read (download JSON)

1. Open the dashboard in the browser
2. Dashboard menu (top-right gear) → **JSON model**
3. Copy/download the JSON

Or fetch via the local snapshot files in `~/code/groundcover/grafana_dashboards/`.

### Edit and re-import

1. Edit the downloaded JSON
2. In Grafana: Dashboard menu → **JSON model** → paste the updated JSON → **Save changes**

Or: Dashboards → New → Import → paste JSON / upload file

### JSON model notes

- `panels` array contains every panel object: `id`, `title`, `type`, `targets` (queries), `gridPos`
- `templating.list` holds template variables
- `uid` **must not change** — it's the stable URL key
- `id` (numeric) and `version` are managed by Grafana; keep them as-is when updating
- `time` sets the default time range; `refresh` sets the auto-refresh interval

---

## Groundcover explore dashboard API (secondary, read-mostly)

These are the native Groundcover "explore" dashboards (not Grafana). Accessible via REST.

```bash
GC_BASE="https://r89vui.platform.grcv.io"
GC_KEY="gcsa_AEAQAAG4_MCMRUZ4D_J642RVJL_SLZRU63O"

# List all dashboards
curl -s "$GC_BASE/api/dashboards" \
  -H "Authorization: Bearer $GC_KEY" \
  -H "X-Backend-Id: us-east1" | python3 -m json.tool

# Get a specific dashboard by UUID
curl -s "$GC_BASE/api/dashboards/{uuid}" \
  -H "Authorization: Bearer $GC_KEY" \
  -H "X-Backend-Id: us-east1" | python3 -m json.tool
```

Write access (PUT) returns 403 — the service account key is read-only for these.
