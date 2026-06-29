# =============================================================================
# Work Configuration (Cyberhaven)
# =============================================================================

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------
#export GOOGLE_CLOUD_PROJECT=ch-dev-ai-playground-cf39
#export VERTEX_LOCATION=us-east1
#export VERTEXAI_PROJECT=es-scalability-test
#export VERTEXAI_REGION=us-east1
export GIT_REPO_PATH="$HOME/code"

# Skaffold
export SKAFFOLD_KUBE_CONTEXT=kind-dataflow
export SKAFFOLD_TRIGGER=manual

# Secrets (API keys/tokens) live in secrets.sh (gitignored).
[ -f "$HOME/.config/secrets.sh" ] && source "$HOME/.config/secrets.sh"
export ASPIRE_API_URL=https://cloud-api.youraspire.com


# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
alias gcov="go tool cover -html=cover.out -o cover.html"
alias k9="TERM=xterm-256color k9s --readonly"
alias k9s='TERM=xterm-256color k9s'
alias ap="aider --model vertex_ai/gemini-2.5-pro"
alias a="aider"
alias kl="sh $HOME/code/shell/kl.sh"
alias klf="sh $HOME/code/shell/klf.sh"

function argopw() {
  kreds es-scalability-test $1
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d | pbcopy
}

function argopf() {
  kubectl port-forward $(kubectl get po -l 'app.kubernetes.io/name=argocd-server' -o name --namespace argocd) 8080:8080 --namespace argocd
}

function argologs() {
  kubectl logs -f -n argocd deploy/argocd-applicationset-controller
}

function argofix() {
  # when that server.secretkey is missing error shows up just
  kubectl rollout restart deploy/argocd-server -n argocd --context gke_es-scalability-test_us-east1-b_shared13
}

function lint() {
  local p=""
  if [[ "$(pwd)" == *"dataflow2"* ]]; then
    p="$GIT_REPO_PATH/dataflow2/dataflow/backend"
  else
    p="$GIT_REPO_PATH/dataflow/backend"
  fi
  cd "$p" && golangci-lint --timeout 15m run --new --config .golangci.yml ./...
}

function pam() {
  local project="${1:?Usage: pam <project> [justification]}"
  local justification="${2:-General investigation}"
  gcloud beta pam grants create \
    --entitlement=data-readers-entitlement \
    --requested-duration=3600s \
    --justification="$justification" \
    --location=global \
    --project="$project"
}

# Runs go tests for packages with changed files relative to the master branch.
#
# This script is designed to be run from the root of the git repository
# (e.g., ~/code/dataflow), where the Go module is located in a subdirectory
# named 'backend'.

function difftests() {
  # These are the two 'gotcha' test packages that should always run.
  local always_run_tests=(
    "./tools/typescript_convertor"
    "./tools/generate_static_client"
  )

  # 1. Get the list of changed files from git diff.
  # 2. Filter for any .go files (including _test.go) inside the 'backend' directory.
  # 3. Get the unique directory names for each changed file.
  # 4. Use sed to remove the 'backend/' prefix, making paths relative to the module root.
  # 5. Use a second sed to prepend './' to each path, marking it as a local package.
  local go_test_dirs
  go_test_dirs=$(git diff --name-only master | \
                 grep '^backend/.*\.go$' | \
                 xargs -I {} dirname {} | \
                 sed 's|^backend/||' | \
                 sort -u | \
                 sed 's|^|./|')

  # Combine the diffed directories with the 'always run' list.
  local all_test_dirs
  all_test_dirs=$(echo -e "${go_test_dirs}\n${always_run_tests[@]}" | sort -u)

  # Check if the variable is empty (no Go files changed).
  if [ -z "$all_test_dirs" ]; then
    echo "No Go files changed in 'backend/'. No tests to run."
    return 0
  fi

  echo "Running tests for the following packages:"
  echo "$all_test_dirs"
  echo "----------------------------------------------------"

  # Use 'go -C backend' to run the command from within the 'backend' directory.
  # This ensures 'go test' can find the go.mod file and resolve packages.
  # xargs passes the directory list (now correctly formatted with ./) to 'go test'.
  echo "$all_test_dirs" | xargs go -C backend test -v
}

# -----------------------------------------------------------------------------
# Terraform / Infrastructure
# -----------------------------------------------------------------------------

function gentf {
  . $GIT_REPO_PATH/environments-templates/templates/workspace/_utils/gen_tf.sh; gen_tf 
}

function cust {
  gh api 'repos/CyberhavenInc/prod-infrastructure/contents/index.md?ref=gh-pages' --header 'Accept: application/vnd.github.v3.raw' | grep "Customer\|prod" | column -t -s $'|'
}

function klogs() {
  k get pods -o name -l app.kubernetes.io/instance=$1 | awk -F'/' '{print $2}' | xargs -I % sh -c 'kubectl logs % -f'
}

function linea_customer_versions() {
  gocode && cd environments-definitions && main
  local props=("app_version" "shared_project_id") # default keys
  props+=("$@")  # append additional keys passed as arguments

  # header
  echo -n "filename"
  for key in "${props[@]}"; do
    echo -n " | $key"
  done
  echo

  for cust in $(yq '.ai_anomaly_detection | select(has("activate") and .activate == true) | filename' --no-doc prod/*.yaml); do
    echo -n "$cust"
    for key in "${props[@]}"; do
      val=$(yq ".$key" "$cust")
      echo -n " | $val"
    done
    echo
  done | sort -t'|' -k2
}

function cat_customer_versions() {
  gocode && cd environments-definitions && main
  local props=("app_version" "shared_project_id") # default keys
  props+=("$@")  # append additional keys passed as arguments

  # header
  echo -n "filename"
  for key in "${props[@]}"; do
    echo -n " | $key"
  done
  echo
  for cust in $(yq 'select(.ai_categorization.categorizer.enabled == true) | filename' --no-doc prod/*.yaml); do
    echo -n "$cust"
    for key in "${props[@]}"; do
      val=$(yq ".$key" "$cust")
      echo -n " | $val"
    done
    echo
  done | sort -t'|' -k2
}

# -----------------------------------------------------------------------------
# Environment Definitions Query Functions
# -----------------------------------------------------------------------------
# All operate on ~/code/environments-definitions. No git pull by default.
# Pass --pull as first arg to any of them to git pull before querying.

ENVDEF_DIR="$HOME/code/environments-definitions"

# envq - General-purpose query across customer YAML files.
#
# Usage:
#   envq <fields...>                              # show fields for all prod customers
#   envq -f 'yq-filter' <fields...>               # filter which files to include
#   envq -e dev|stage|prod <fields...>             # target a different env (default: prod)
#   envq -s <N> <fields...>                        # sort by column N (1-indexed, default: 1)
#   envq --pull <fields...>                        # git pull before querying
#   envq --tsv <fields...>                         # tab-separated (for piping)
#
# Fields are dot-paths: app_version, shared_project_id, ai_categorization.categorizer.enabled, etc.
#
# Filter is a yq expression that selects matching docs. Examples:
#   -f '.ai_categorization.categorizer.enabled == true'
#   -f '.shared_project_id == "prod-group-1"'
#   -f '.cluster_region == "us-east1"'
#   -f '.ai_anomaly_detection.activate == true and .ai_categorization.categorizer.enabled == true'
#
# Examples:
#   envq app_version shared_project_id
#   envq -f '.ai_categorization.categorizer.enabled == true' customer_name shared_project_id cluster_region
#   envq -f '.shared_project_id == "prod-group-1"' customer_name app_version
#   envq -s 2 customer_name shared_project_id
#   envq -e stage app_version
function envq() {
  local env="prod"
  local filter=""
  local sort_col=1
  local sep=" | "
  local do_pull=false
  local fields=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pull)   do_pull=true; shift ;;
      --tsv)    sep=$'\t'; shift ;;
      -e)       env="$2"; shift 2 ;;
      -f)       filter="$2"; shift 2 ;;
      -s)       sort_col="$2"; shift 2 ;;
      -h|--help)
        echo "Usage: envq [-e env] [-f 'yq-filter'] [-s sort-col] [--pull] [--tsv] <field> [field...]"
        echo ""
        echo "Fields:  dot-paths like app_version, shared_project_id, ai_categorization.categorizer.enabled"
        echo "Filter:  yq boolean expression, e.g. '.ai_categorization.categorizer.enabled == true'"
        echo "Env:     prod (default), dev, stage"
        echo "Sort:    column number (1=filename, 2=first field, ...)"
        return 0 ;;
      *)        fields+=("$1"); shift ;;
    esac
  done

  if [[ ${#fields[@]} -eq 0 ]]; then
    echo "Usage: envq [-e env] [-f filter] [-s col] [--pull] [--tsv] <field> [field...]" >&2
    return 1
  fi

  local dir="$ENVDEF_DIR"
  if $do_pull; then
    git -C "$dir" pull --quiet
  fi

  # Build yq select expression
  local selector="select(filename != \"*/_*\")"  # skip _defaults, _waves
  if [[ -n "$filter" ]]; then
    selector="select($filter)"
  fi

  # header
  local header="customer"
  for f in "${fields[@]}"; do
    header+="${sep}${f}"
  done
  echo "$header"

  # query — use eval to ensure glob expansion in zsh
  local file_list
  file_list=($(eval "yq '$selector | filename' --no-doc $dir/$env/*.yaml 2>/dev/null"))

  for cust in "${file_list[@]}"; do
    # skip _defaults.yaml, _waves.yaml
    local base=$(basename "$cust")
    [[ "$base" == _* ]] && continue

    local name="${base%.yaml}"
    local line="$name"
    for key in "${fields[@]}"; do
      local val=$(yq ".$key // \"—\"" "$cust" 2>/dev/null)
      line+="${sep}${val}"
    done
    echo "$line"
  done | sort -t'|' -k"$sort_col"
}

# envgrp - List customers grouped by shared_project_id (prod group).
#
# Usage:
#   envgrp                        # show all groups with customer counts + regions
#   envgrp <group-name>           # list customers in a specific group
#   envgrp prod-group-1           # example
#   envgrp -v <group-name>        # verbose: include region + version
#   envgrp --pull                 # git pull first
function envgrp() {
  local verbose=false
  local do_pull=false
  local target=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pull) do_pull=true; shift ;;
      -v)     verbose=true; shift ;;
      -h|--help)
        echo "Usage: envgrp [-v] [--pull] [group-name]"
        echo "  No args: show all groups with customer counts + regions"
        echo "  With group: list customers in that group"
        echo "  -v: verbose (show region + version)"
        return 0 ;;
      *)      target="$1"; shift ;;
    esac
  done

  local dir="$ENVDEF_DIR"
  if $do_pull; then git -C "$dir" pull --quiet; fi

  if [[ -z "$target" ]]; then
    # Summary mode: group -> count + regions
    echo "prod_group | count | regions"
    yq '[.shared_project_id // "unknown", .cluster_region // "(default)"] | @tsv' --no-doc "$dir"/prod/ch-prod-*.yaml 2>/dev/null \
      | awk -F'\t' '{
          cnt[$1]++
          if (!seen[$1,$2]++) {
            regions[$1] = (regions[$1] ? regions[$1] ", " : "") $2
          }
        } END {
          for (g in cnt) printf "%s | %s | %s\n", g, cnt[g], regions[g]
        }' | sort -t'|' -k2 -rn
  else
    # Detail mode: list customers in a group
    if $verbose; then
      echo "customer | customer_name | cluster_region | app_version"
    else
      echo "customer | customer_name | cluster_region"
    fi
    for f in "$dir"/prod/ch-prod-*.yaml; do
      local grp=$(yq '.shared_project_id // ""' "$f" 2>/dev/null)
      [[ "$grp" != "$target" ]] && continue
      local base=$(basename "$f" .yaml)
      local name=$(yq '.customer_name // "—"' "$f" 2>/dev/null)
      local region=$(yq '.cluster_region // "(default)"' "$f" 2>/dev/null)
      if $verbose; then
        local ver=$(yq '.app_version // "—"' "$f" 2>/dev/null)
        echo "$base | $name | $region | $ver"
      else
        echo "$base | $name | $region"
      fi
    done | sort
  fi
}

# envregions - Show which regions each prod group covers.
#
# Usage:
#   envregions                    # all groups and their regions
#   envregions --mixed             # only groups with >1 distinct region
#   envregions --pull              # git pull first
function envregions() {
  local mixed_only=false
  local do_pull=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mixed) mixed_only=true; shift ;;
      --pull)  do_pull=true; shift ;;
      -h|--help)
        echo "Usage: envregions [--mixed] [--pull]"
        echo "  (default): all groups with their region(s)"
        echo "  --mixed:   only groups with >1 distinct region"
        return 0 ;;
      *)       echo "Unknown option: $1" >&2; return 1 ;;
    esac
  done

  local dir="$ENVDEF_DIR"
  if $do_pull; then git -C "$dir" pull --quiet; fi

  echo "prod_group | customers | regions"
  yq '[.shared_project_id // "unknown", .cluster_region // "(default)"] | @tsv' --no-doc "$dir"/prod/ch-prod-*.yaml 2>/dev/null \
    | awk -F'\t' -v mixed="$mixed_only" '{
        cnt[$1]++
        if (!seen[$1,$2]++) {
          n[$1]++
          regions[$1] = (regions[$1] ? regions[$1] ", " : "") $2
        }
      } END {
        for (g in cnt) {
          if (mixed == "true" && n[g] < 2) continue
          printf "%s | %s | %s\n", g, cnt[g], regions[g]
        }
      }' | sort
}

# envai - Quick view of AI feature flags across customers.
#
# Usage:
#   envai                              # show all customers with any AI feature enabled
#   envai --all                         # show all customers (including AI disabled)
#   envai --cat                         # only ai_categorization.categorizer.enabled == true
#   envai --cat --by-group              # categorization customers grouped by prod group
#   envai --linea                       # only ai_anomaly_detection.activate == true
#   envai --pull                        # git pull first
function envai() {
  local filter_mode="any"  # any | all | cat | linea
  local by_group=false
  local do_pull=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)      filter_mode="all"; shift ;;
      --cat)      filter_mode="cat"; shift ;;
      --linea)    filter_mode="linea"; shift ;;
      --by-group) by_group=true; shift ;;
      --pull)     do_pull=true; shift ;;
      -h|--help)
        echo "Usage: envai [--all|--cat|--linea] [--by-group] [--pull]"
        echo "  (default):   customers with any AI feature enabled"
        echo "  --all:       all customers"
        echo "  --cat:       only categorization enabled"
        echo "  --linea:     only anomaly detection activated"
        echo "  --by-group:  group output by shared_project_id"
        return 0 ;;
      *)       echo "Unknown option: $1" >&2; return 1 ;;
    esac
  done

  local dir="$ENVDEF_DIR"
  if $do_pull; then git -C "$dir" pull --quiet; fi

  # Collect rows
  local rows=""
  for f in "$dir"/prod/ch-prod-*.yaml; do
    local cat_on=$(yq '.ai_categorization.categorizer.enabled // false' "$f" 2>/dev/null)
    local linea_on=$(yq '.ai_anomaly_detection.activate // false' "$f" 2>/dev/null)

    case "$filter_mode" in
      cat)   [[ "$cat_on" != "true" ]] && continue ;;
      linea) [[ "$linea_on" != "true" ]] && continue ;;
      any)   [[ "$cat_on" != "true" && "$linea_on" != "true" ]] && continue ;;
      all)   ;;
    esac

    local base=$(basename "$f" .yaml)
    local name=$(yq '.customer_name // "—"' "$f" 2>/dev/null)
    local grp=$(yq '.shared_project_id // "—"' "$f" 2>/dev/null)
    local region=$(yq '.cluster_region // "(default)"' "$f" 2>/dev/null)
    local ver=$(yq '.app_version // "—"' "$f" 2>/dev/null)
    rows+="$grp\t$base\t$name\t$region\t$cat_on\t$linea_on\t$ver\n"
  done

  if $by_group; then
    # Grouped display
    local sorted=$(echo -e "$rows" | sort -t$'\t' -k1,1 -k2,2)
    local prev_grp=""
    local grp_count=0
    echo -e "$sorted" | while IFS=$'\t' read -r grp cust name region cat linea ver; do
      [[ -z "$grp" ]] && continue
      if [[ "$grp" != "$prev_grp" ]]; then
        [[ -n "$prev_grp" ]] && echo ""
        echo "── $grp ──"
        prev_grp="$grp"
      fi
      echo "  $cust | $name | $region | cat=$cat | linea=$linea"
    done
    # Summary count
    local total=$(echo -e "$rows" | grep -c '.')
    local groups=$(echo -e "$rows" | awk -F'\t' '{print $1}' | sort -u | grep -c '.')
    echo ""
    echo "Total: $total customers across $groups prod groups"
  else
    echo "customer | customer_name | prod_group | region | categorizer | anomaly_detect | app_version"
    echo -e "$rows" | sort -t$'\t' -k1,1 -k2,2 \
      | awk -F'\t' '{printf "%s | %s | %s | %s | %s | %s | %s\n", $2, $3, $1, $4, $5, $6, $7}'
  fi
}

# envwave - Show which wave each customer is on (from _waves.yaml).
#
# Usage:
#   envwave                    # show all customers and their waves
#   envwave <customer>         # show wave for a specific customer (e.g. ch-prod-09i)
#   envwave --wave <name>      # list customers in a specific wave
#   envwave --pull             # git pull first
function envwave() {
  local target_cust=""
  local target_wave=""
  local do_pull=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pull)  do_pull=true; shift ;;
      --wave)  target_wave="$2"; shift 2 ;;
      -h|--help)
        echo "Usage: envwave [--pull] [--wave wave-name] [customer]"
        return 0 ;;
      *)       target_cust="$1"; shift ;;
    esac
  done

  local dir="$ENVDEF_DIR"
  if $do_pull; then git -C "$dir" pull --quiet; fi
  local waves_file="$dir/prod/_waves.yaml"

  if [[ -n "$target_wave" ]]; then
    # Show customers in a specific wave
    local ver=$(yq ".$target_wave.version // \"—\"" "$waves_file" 2>/dev/null)
    echo "wave: $target_wave (version: $ver)"
    echo "---"
    yq ".$target_wave.workspaces[]" "$waves_file" 2>/dev/null | sort
    return
  fi

  # Build a map: workspace -> wave name + version
  local waves=$(yq 'to_entries[] | .key as $wave | .value.version as $ver | .value.workspaces[]? | [., $wave, $ver] | @tsv' "$waves_file" 2>/dev/null)

  if [[ -n "$target_cust" ]]; then
    # Look up a single customer
    echo "$waves" | awk -F'\t' -v c="$target_cust" '$1 == c { printf "%s | wave: %s | version: %s\n", $1, $2, $3 }'
    return
  fi

  # Show all
  echo "customer | wave | version"
  echo "$waves" | awk -F'\t' '{ printf "%s | %s | %s\n", $1, $2, $3 }' | sort
}

SLMINV="$HOME/code/llmops-procedures/deployments/prod-group-inventory.yaml"

# envslm - Query and update the SLM prod-group inventory.
#
# Usage:
#   envslm                              # show all prod groups with status + mode + cluster count
#   envslm --deployed                    # only deployed groups
#   envslm --keep-llm                    # only keep-llm groups
#   envslm --status <status>             # filter by any status
#   envslm -g <group>                    # show details for one group
#   envslm -g <group> --set-clusters N   # update categorizer_clusters for a group
#   envslm --customers                   # cross-ref with env-defs: show SLM customers
#   envslm --pull                        # git pull first (both repos)
function envslm() {
  local do_pull=false
  local status_filter=""
  local target_group=""
  local set_clusters=""
  local show_customers=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pull)           do_pull=true; shift ;;
      --deployed)       status_filter="deployed"; shift ;;
      --keep-llm)       status_filter="keep-llm"; shift ;;
      --deferred)       status_filter="deferred"; shift ;;
      --planned)        status_filter="planned"; shift ;;
      --status)         status_filter="$2"; shift 2 ;;
      -g)               target_group="$2"; shift 2 ;;
      --set-clusters)   set_clusters="$2"; shift 2 ;;
      --customers)      show_customers=true; shift ;;
      -h|--help)
        echo "Usage: envslm [--deployed|--keep-llm|--status S] [-g group [--set-clusters N]] [--customers] [--pull]"
        echo ""
        echo "  (default):       all prod groups with status, mode, clusters, region"
        echo "  --deployed:      only deployed groups"
        echo "  --keep-llm:      only keep-llm groups"
        echo "  --status S:      filter by any status"
        echo "  -g <group>:      show full details for one group"
        echo "  --set-clusters N: update categorizer_clusters for the group (requires -g)"
        echo "  --customers:     cross-ref with env-defs: which customers are on SLM groups?"
        return 0 ;;
      *)       echo "Unknown option: $1" >&2; return 1 ;;
    esac
  done

  if $do_pull; then
    git -C "$(dirname "$SLMINV")" pull --quiet 2>/dev/null
    git -C "$ENVDEF_DIR" pull --quiet 2>/dev/null
  fi

  # Update categorizer_clusters (uses sed to preserve formatting)
  if [[ -n "$set_clusters" ]]; then
    if [[ -z "$target_group" ]]; then
      echo "Error: --set-clusters requires -g <group>" >&2
      return 1
    fi
    local old=$(yq ".prod_groups.\"$target_group\".categorizer_clusters" "$SLMINV" 2>/dev/null)
    if [[ "$old" == "null" ]]; then
      echo "Error: $target_group has no categorizer_clusters field" >&2
      return 1
    fi
    # Find the group's block and update categorizer_clusters within it
    sed -i '' "/^  ${target_group}:/,/^  [a-z]/ s/\(categorizer_clusters:\) ${old}/\1 ${set_clusters}/" "$SLMINV"
    echo "Updated $target_group: categorizer_clusters $old -> $set_clusters"
    return
  fi

  # Single group detail
  if [[ -n "$target_group" ]]; then
    yq ".prod_groups.\"$target_group\"" "$SLMINV" 2>/dev/null
    return
  fi

  # Cross-reference: SLM customers
  if $show_customers; then
    echo "prod_group | status | mode | customer | customer_name | region"
    local groups=$(yq '.prod_groups | to_entries[] | [.key, .value.status, .value.mode // "—"] | @tsv' "$SLMINV" 2>/dev/null)
    echo "$groups" | while IFS=$'\t' read -r grp grp_status mode; do
      [[ -z "$grp" ]] && continue
      [[ -n "$status_filter" && "$grp_status" != "$status_filter" ]] && continue
      for f in "$ENVDEF_DIR"/prod/ch-prod-*.yaml; do
        local fgrp=$(yq '.shared_project_id // ""' "$f" 2>/dev/null)
        [[ "$fgrp" != "$grp" ]] && continue
        local cat_on=$(yq '.ai_categorization.categorizer.enabled // false' "$f" 2>/dev/null)
        [[ "$cat_on" != "true" ]] && continue
        local base=$(basename "$f" .yaml)
        local name=$(yq '.customer_name // "—"' "$f" 2>/dev/null)
        local region=$(yq '.cluster_region // "(default)"' "$f" 2>/dev/null)
        echo "$grp | $grp_status | $mode | $base | $name | $region"
      done
    done | sort
    return
  fi

  # Summary table
  echo "prod_group | status | mode | clusters | region | tier"
  yq '.prod_groups | to_entries[] | [
    .key,
    .value.status,
    .value.mode // "—",
    .value.categorizer_clusters // "—",
    .value.cluster_region // .value.preferred_endpoint_region // "—",
    .value.slm.tier // "—"
  ] | @tsv' "$SLMINV" 2>/dev/null \
    | while IFS=$'\t' read -r grp grp_status mode clusters region tier; do
      [[ -n "$status_filter" && "$grp_status" != "$status_filter" ]] && continue
      echo "$grp | $grp_status | $mode | $clusters | $region | $tier"
    done | sort
}

# envfind - Find a customer by partial name, subdomain, or cluster code.
#
# Usage:
#   envfind primer               # search by customer_name or subdomain
#   envfind 09i                  # search by cluster code
#   envfind --pull primer        # git pull first
function envfind() {
  local do_pull=false
  local query=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pull) do_pull=true; shift ;;
      -h|--help) echo "Usage: envfind [--pull] <search-term>"; return 0 ;;
      *)      query="$1"; shift ;;
    esac
  done

  if [[ -z "$query" ]]; then
    echo "Usage: envfind <search-term>" >&2
    return 1
  fi

  local dir="$ENVDEF_DIR"
  if $do_pull; then git -C "$dir" pull --quiet; fi

  echo "customer | customer_name | subdomain | prod_group | region"
  for f in "$dir"/prod/ch-prod-*.yaml; do
    local base=$(basename "$f" .yaml)
    local name=$(yq '.customer_name // ""' "$f" 2>/dev/null)
    local sub=$(yq '.subdomain // ""' "$f" 2>/dev/null)

    # Case-insensitive match on filename, customer_name, or subdomain
    if echo "$base $name $sub" | grep -qi "$query"; then
      local grp=$(yq '.shared_project_id // "—"' "$f" 2>/dev/null)
      local region=$(yq '.cluster_region // "—"' "$f" 2>/dev/null)
      echo "$base | $name | $sub | $grp | $region"
    fi
  done | sort
}


# -----------------------------------------------------------------------------
# Release / Backport Functions
# -----------------------------------------------------------------------------

# Check out a release branch and update it
function release() {
  local branch="platform-core/${1:-25\.10}.01" # default to recent one
  gc "$branch" && gpu
}

function backport() {
  if [ "$#" -ne 3 ]; then
      echo "Usage: backport [arguments]"
      echo "Arguments:"
      echo "  \$1    Branch prefix"
      echo "  \$2    Releases to backport to"
      echo "  \$3    SHAs to cherry-pick"
      return 1
  fi

  # Input arguments
  local branch_prefix=$1
  local releases="$2"
  local shas="$3"

  # Convert the comma-separated strings into arrays
  IFS=',' release_array=("${(s/,/)releases}")
  IFS=',' sha_array=("${(s/,/)shas}")

  # Loop through each release
  for r in "${release_array[@]}"; do
    echo "Processing release: $r"

    # Run the release command to checkout the platform-core/${r} branch and update it
    if [ "$r" = "master" ]; then
      master
    else
      release $r
    fi

    # Checkout the branch with the prefix
    gc -b "$branch_prefix-$r"

    # Loop through each SHA
    for sha in "${sha_array[@]}"; do
        echo "Processing SHA: $sha"
        # Run gcp for the SHA
        gcp $sha

        # Check if the cherry-pick resulted in a dirty git status (i.e., conflicts)
        if git status --porcelain | grep -q '^[A-Z][A-Z] '; then
          echo "Error: Conflict detected after cherry-picking $sha."
          echo "Please resolve the conflict manually before continuing."
          return 1
        fi
    done

    echo "Publishing branch..."
    gpp
  done
}



# -----------------------------------------------------------------------------
# Kubernetes Functions
# -----------------------------------------------------------------------------

function kreds() {
  # If only one argument is provided, treat it as the shortcut.
  # Example: "hzb" becomes "ch-prod-hzb" and "prod-hzb".
  if [[ $# -eq 1 && -n "$1" ]]; then
    if [[ "dogfood" == "$1" ]]; then
      set -- "dogfood-275714" "prod-dogfood"
    elif [[ "release" == "$1" ]]; then
      set -- "es-scalability-test" "radu-jenkins-cluster"
    elif [[ "release2" == "$1" ]]; then
      set -- "es-scalability-test" "radu-jenkins-cluster2"
    elif [[ "release-candidate" == "$1" ]]; then
      set -- "cyberhaven-release-candidate" "release-candidate"
    elif [[ "release-product" == "$1" ]]; then
      set -- "ch-release-product" "release-product"
    elif [[ "demo2a" == "$1" ]]; then
      set -- "cyberhaven-demo" "demo2a"
    else
      set -- "ch-prod-${1}" "prod-${1}"
    fi
  fi

  local project_id=$1
  local cluster_name=$2
  local region=$3
  if [[ -z "$region" ]]; then
    echo "Discovering cluster location..."
    region=$(gcloud container clusters list --project="$project_id" --filter="name=$cluster_name" --format="value(location)" 2>/dev/null)
    if [[ -z "$region" ]]; then
      region="us-east1-b"  # fallback
      echo "Could not auto-detect region, using default: $region"
    fi
  fi

  # Check if required arguments are provided
  if [[ -z "$project_id" || -z "$cluster_name" ]]; then
    echo "Usage: kreds <project_id> <cluster_name> [region]"
    echo "   or: kreds <customer_code_shortcut>"
    return 1
  fi
  
  # --- 1. Define Known DNS Clusters ---
  local dns_flag=""
  local dns_clusters=("prod-dogfood" "stage-rc0" "stage-rc1" "stage-rc2" "stage-rc3" "stage-rc4" "stage-rc5" "stage-rc6" "stage-rc7" "stage-rc8" "prod-09i" "prod-0pw" "prod-12l" "prod-3hv" "prod-4mp" "prod-4ud" "prod-54k" "prod-7pg" "prod-99l" "prod-9io" "prod-9ms" "prod-prod" "prod-a3l" "prod-a4r" "prod-a7l" "prod-a87" "prod-a8h" "prod-a8r" "prod-acc" "prod-acs" "prod-adr" "prod-ait" "prod-alk" "prod-alm" "prod-ap1" "prod-arx" "prod-ash" "prod-ath" "prod-avy" "prod-b2z" "prod-bkc" "prod-c2f" "prod-c9n" "prod-cbr" "prod-cg2" "prod-cie" "prod-cnc" "prod-co7" "prod-coh" "prod-cr2" "prod-crs" "prod-cse" "prod-cy3" "prod-d5a" "prod-dc2" "prod-dd2" "prod-demo4" "prod-dlp" "prod-ds6" "prod-eago9" "prod-ee9" "prod-ej1" "prod-er3" "prod-ers" "prod-esg" "prod-fa1" "prod-ff2" "prod-ffl" "prod-flv" "prod-ftl" "prod-fwb" "prod-g3h" "prod-gaw" "prod-prod" "prod-gh7" "prod-gnf" "prod-gps" "prod-gs7" "prod-hhr" "prod-hj3" "prod-hlg" "prod-prod" "prod-i6d" "prod-ih9" "prod-im1" "prod-io0" "prod-ipt" "prod-irm" "prod-j1a" "prod-jh3" "prod-jhm" "prod-k09" "prod-k6l" "prod-key" "prod-kg3" "prod-ki2" "prod-kls" "prod-kr7" "prod-l0p" "prod-l9e" "prod-lp3" "prod-m8s" "prod-mm3" "prod-mn3" "prod-mpg" "prod-prod" "prod-mpp" "prod-mv2" "prod-n52" "prod-n7a" "prod-n8x" "prod-nls" "prod-oe3" "prod-op7" "prod-pen" "prod-pim" "prod-pl8" "prod-pl9" "prod-pv4" "prod-pyc" "prod-q38" "prod-qw2" "prod-r4v" "prod-r6x" "prod-rdt" "prod-re9" "prod-rks" "prod-rp2" "prod-rr2" "prod-rrd" "prod-s3f" "prod-s5a" "prod-sfl" "prod-smc" "prod-spx" "prod-ssb" "prod-sup" "prod-sv8" "prod-sx8" "prod-t3g" "prod-t7e" "prod-ta8" "prod-tcd" "prod-tp4" "prod-tqh" "prod-uf2" "prod-um7" "prod-ux1" "prod-ux2" "prod-ux3" "prod-ux4" "prod-v6a" "prod-vca" "prod-vcu" "prod-vep" "prod-vtt" "prod-wal23r" "prod-wk1" "prod-wlv" "prod-wsa" "prod-x23" "prod-xs9" "prod-xzq" "prod-yh2" "prod-yx2" "prod-27254bce" "prod-mx1" "dogfood-275714" "prod-tg8"
)

  # Check if the current cluster is in the "known" list
  for c in "${dns_clusters[@]}"; do
    if [[ "$cluster_name" == "$c" ]]; then
      dns_flag="--dns-endpoint"
      break
    fi
  done

  # --- 2. First Attempt ---
  # We include $dns_flag (it will be empty for most clusters)
  echo "Attempting: gcloud container clusters get-credentials $cluster_name --zone $region --project $project_id $dns_flag"
  gcloud container clusters get-credentials "$cluster_name" \
    --zone "$region" \
    --project "$project_id" \
    $dns_flag

  # --- 3. Fallback Attempt ---
  # If the first attempt failed (or the flag was missing and needed), try with the flag explicitly
  if ! kubectl get namespace &>/dev/null; then
    # Only retry if we haven't already tried the dns-endpoint
    if [[ -z "$dns_flag" ]]; then
      echo "Normal auth failed, retrying with --dns-endpoint..."
      gcloud container clusters get-credentials "$cluster_name" \
        --zone "$region" \
        --project "$project_id" \
        --dns-endpoint
    else
      echo "Auth failed even with --dns-endpoint. Please check your connection or permissions."
      return 1
    fi
  fi
}

function appset() {
  local set_name=$1
  if [[ -z "$set_name" ]]; then
    echo "Usage: appset <set_name>"
    return 1
  fi
  kubectl edit appset/$set_name -n argocd
}

function kversion() {
  local deployment_name=$1

  # Check if required arguments are provided
  if [[ -z "$deployment_name" ]]; then
    echo "Usage: kversion <deployment_name>"
    return 1
  fi
  kubectl get deployment "$deployment_name" -o jsonpath='{.spec.template.spec.containers[*].image}{"\n"}'
}

# -----------------------------------------------------------------------------
# Elasticsearch Functions
# -----------------------------------------------------------------------------

function erefresh() {
  local _index=${1:-notifications} # defaults to notifications
  echo "Using index=$_index"
  curl -H "Content-Type: application/json" -s -k -X POST "https://localhost:9200/$_index/_refresh" \
    -u elastic:$(kubectl get secret secrets -o jsonpath='{.data.es-credentials}' | base64 -d | jq .password -r) | jq
}

function es() {
  local _id=$1
  local _index=${2:-'notifications'} # defaults to notifications
  echo "Using index=$_index"
  # {\"query\":{\"terms\":{\"_id\":[\"$1\"]}}}
  # $(kubectl get secret secrets -o jsonpath='{.data.es-credentials}' | base64 -d | jq .password -r)
  curl -H "Content-Type: application/json" -s -k -X GET "https://localhost:9200/$_index/_search" -d "$1" \
    -u elastic:elastic | jq
}


function eindices() {
  curl -H "Content-Type: application/json" -k -X GET "https://localhost:9200/_cat/indices" \
    -u elastic:$(kubectl get secret secrets -o jsonpath='{.data.es-credentials}' | base64 -d | jq .password -r)
}

function epost() {
  local search=$1
  local _index=${2:-notifications} # defaults to notifications
  echo "Using index=$_index"
  curl -H "Content-Type: application/json" -s -k -X POST "https://localhost:9200/$_index/_update_by_query" -d "$search" \
    -u elastic:$(kubectl get secret secrets -o jsonpath='{.data.es-credentials}' | base64 -d | jq .password -r) | jq
}


function notification_count() {
  local _index=${1:-notifications} # defaults to notifications
  echo "Using index=$_index"
  # notifications?v&h=index,store.size,docs.count
  # _cat/indices?v
  curl -H "Content-Type: application/json" -s -k -X GET "https://localhost:9200/_cat/indices/$_index?v&h=index,store.size,docs.count" \
    -u elastic:$(kubectl get secret secrets -o jsonpath='{.data.es-credentials}' | base64 -d | jq .password -r)

}

dr_gentf() {
  # Save the current directory
  local original_dir=$(pwd)

  # Ensure two arguments are provided
  if [[ $# -ne 2 ]]; then
      echo "Error: Missing arguments."
      echo "Usage: dr_gentf <dev|prod> <cluster, e.g. labs or ch-prod-mdr>"
      return 1  # Use `return` instead of `exit` to avoid closing the terminal
  fi

  cd ~/code/ || { echo "Error: Failed to change to ~/code"; return 1; }


  mkdir -p ~/venv/cookiecutter/
  #python3 -m venv ~/venv/cookiecutter/
  /usr/local/bin/python3.13 -m venv ~/venv/cookiecutter/
  . ~/venv/cookiecutter/bin/activate
  pip3 install -r ./environments-templates/templates/workspace/requirements.txt
  pip install jinja2-git
  pip3 install jinja2-git
  pip show jinja2-git

  GIT_REPO_PATH=~/code
  cd "$GIT_REPO_PATH" || { echo "Error: Failed to change to $GIT_REPO_PATH"; return 1; }

  local env="$1"
  local subdir="$2"
  local repo

  case "$env" in
      dev)
          repo="dev-playground"
          subdir="es-scalability-test_${subdir}"
          ;;
      prod)
          repo="prod-infrastructure"
          ;;
      *)
          echo "Error: Invalid environment. Use 'dev' or 'prod'."
          return 1
          ;;
  esac

  cd "$repo/$subdir" || { echo "Error: Failed to change directory to $repo/$subdir"; return 1; }

  # Run the Terraform generation script
  . "$GIT_REPO_PATH/environments-templates/templates/workspace/_utils/gen_tf.sh"
  gen_tf

  # Return to the original directory
  cd "$original_dir" || echo "Warning: Failed to return to original directory: $original_dir"
}

