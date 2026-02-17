# =============================================================================
# Work Configuration (Cyberhaven)
# =============================================================================

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------
export GOOGLE_CLOUD_PROJECT=ch-dev-ai-playground-cf39
export VERTEX_LOCATION=us-east1
export VERTEXAI_PROJECT=es-scalability-test
export VERTEXAI_REGION=us-east1
export GIT_REPO_PATH="$HOME/code"

# Skaffold
export SKAFFOLD_KUBE_CONTEXT=kind-dataflow
export SKAFFOLD_TRIGGER=manual

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

function lint() {
  local p=""
  if [[ "$(pwd)" == *"dataflow2"* ]]; then
    p="$GIT_REPO_PATH/dataflow2/dataflow/backend"
  else
    p="$GIT_REPO_PATH/dataflow/backend"
  fi
  cd "$p" && golangci-lint --timeout 15m run --new --config .golangci.yml ./...
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

function taildebug() {
  k get pods -o name -l app.kubernetes.io/instance=debug-ai-analyst | awk -F'/' '{print $2}' | xargs -I % sh -c \
    'kubectl logs % -f --tail=500 | grep -v -E "GET /metrics|GET /healthcheck|GET /liveness"'
}

function dldebug() {
  local lines=${1:-500}  # Default to 500 lines if no argument is provided
  local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")  # Current timestamp
  local output_dir=~/Desktop/linea
  local output_file="${output_dir}/${timestamp}_debug-ai-analyst_logs.log"

  # Ensure the destination directory exists
  mkdir -p "${output_dir}"

  # Collect logs and write to the file
  echo "Writing logs to ${output_file}..."
  k get pods -o name -l app.kubernetes.io/instance=debug-ai-analyst | awk -F'/' '{print $2}' | xargs -I % sh -c \
    "kubectl logs % --tail=${lines} | grep -v -E 'GET /metrics|GET /healthcheck|GET /liveness'" > "${output_file}"

  echo "Logs have been saved to ${output_file}."
  vim "${output_file}"
}

##function linea_customer_versions() {
  ##gocode && cd environments-definitions && main
  ##for cust in $(yq '.ai_anomaly_detection | select(has("activate") and .activate == true) | filename' --no-doc prod/*.yaml); do echo $cust $(yq '.app_version' $cust) $(yq '.shared_project_id' $cust); done | sort -k2
##}

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

# Linea Replay Logs
#
function linea() {
  # Get the pod name (strip the "pod/" prefix if present)
  local pod_name=$(kubectl get pods -n default --selector=job-name=lineareplay -o name | awk -F'/' '{print $2}')

  # Get the current timestamp
  local now=$(date +"%Y%m%d%H%M%S")

  # Save logs to a file, naming it with the timestamp and pod name
  kubectl logs -n default $pod_name > ~/Desktop/linea/${now}_${pod_name}.log
  vim ~/Desktop/linea/${now}_${pod_name}.log
}

# -----------------------------------------------------------------------------
# Release / Backport Functions
# -----------------------------------------------------------------------------

# Check out a release branch and update it
function release() {
  local branch="platform-core/${1:-25\.10}" # default to recent one
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
      set -- "cyberhave-release-candidate" "release-candidate"
    elif [[ "release-product" == "$1" ]]; then
      set -- "ch-release-product" "release-product"
    else
      set -- "ch-prod-${1}" "prod-${1}"
    fi
  fi

  local project_id=$1
  local cluster_name=$2
  local region=${3:-us-east1-b}  # Default to us-east1-b if not provided

  # Check if required arguments are provided
  if [[ -z "$project_id" || -z "$cluster_name" ]]; then
    echo "Usage: kreds <project_id> <cluster_name> [region]"
    echo "   or: kreds <customer_code_shortcut>"
    return 1
  fi
  
  # First attempt normal auth
  echo "Attempting: gcloud container clusters get-credentials $cluster_name --zone $region --project $project_id"
  gcloud container clusters get-credentials "$cluster_name" \
    --zone "$region" \
    --project "$project_id"

  # Test if we can connect; if not, retry with --dns-endpoint
  if ! kubectl get namespace &>/dev/null; then
    echo "Normal auth failed, retrying with --dns-endpoint..."
    gcloud container clusters get-credentials "$cluster_name" \
      --zone "$region" \
      --project "$project_id" \
      --dns-endpoint
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

function esearchid() {
  local _id=$1
  local _index=${2:-notifications} # defaults to notifications
  echo "Using index=$_index"
  curl -H "Content-Type: application/json" -s -k -X GET "https://localhost:9200/$_index/_search" -d "{\"query\":{\"terms\":{\"_id\":[\"$1\"]}}}" \
    -u elastic:fQcQrgpDDDHtICapUnheng
}

function esearch() {
  local search=$1
  local _index=${2:-notifications} # defaults to notifications
  echo "Using index=$_index"
  curl -H "Content-Type: application/json" -s -k -X GET "https://localhost:9200/$_index/_search" -d "$search" \
    -u elastic:fQcQrgpDDDHtICapUnheng
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

function close_inc() {
  local _index=${1:-notifications} # defaults to notifications
  echo "Using index=$_index"
  # notifications?v&h=index,store.size,docs.count
  # _cat/indices?v
  output=$(curl -X POST "http://localhost:9200/$_index/_update_by_query" \
    -H "Content-Type: application/json" -s -k \
    -u elastic:$(kubectl get secret secrets -o jsonpath='{.data.es-credentials}' | base64 -d | jq .password -r) \
    -d '{
  "script": {
    "source": "
      // Get the current UTC time
      def now = ZonedDateTime.now(ZoneOffset.UTC).toString();
      
      ctx._source.resolution_status = '\''ignored'\'';
      ctx._source.resolution_time = now;
      ctx._source.close_reason = '\''invalid_dataset'\'';
      
      // Initialize admin_history array if it not there
      if (ctx._source.admin_history == null) {
        ctx._source.admin_history = [];
      }
      
      // Add the new admin_history entry
      ctx._source.admin_history.add([
        '\''time'\'': now,
        '\''user'\'': '\''david.riott@cyberhaven.com'\'',
        '\''new_status'\'': '\''ignored'\'',
        '\''assignee'\'': '\''\'',
        '\''unblocked'\'': false,
        '\''close_reason'\'': '\''invalid_dataset'\'',
        '\''close_note'\'': '\''\''
      ]);
    ",
    "lang": "painless"
  },
  "query": {
    "term": {
      "resolution_status": "unresolved"
      "_id": "uqimv48Bw-Lrn-LFyzTy-095e2b4b-672f-4fc9-801a-552d0647e66a_fd440177-c1fa-4548-8f63-1d228ed5c915"
    }
  },
  "size": 1
}')
echo "$output"
}

# -----------------------------------------------------------------------------
# YAML / Infrastructure Utilities
# -----------------------------------------------------------------------------

agg_yaml() {
    # Check if the directory is provided as an argument; otherwise, use the current directory.
    local dir=${1:-.}

    # Initialize an associative array to store results
    declare -A results

    # Loop through all yaml files in the directory
    for file in "$dir"/*.yaml; do
        if [[ -f "$file" ]]; then
            # Initialize values for each property to "not found"
            local spanner_enabled="not found"
            local migrations_enabled="not found"
            local services_enabled="not found"
            
            # Use grep with context to find nested keys
            spanner_enabled=$(grep -A 3 'spanner:' "$file" | grep -E '^\s*enabled:' | awk -F': ' '{print $2}' | xargs)
            migrations_enabled=$(grep -A 3 'spanner:' "$file" | grep '^\s*migrations_enabled:' | awk -F': ' '{print $2}' | xargs)
            services_enabled=$(grep -A 3 'spanner:' "$file" | grep '^\s*services_enabled:' | awk -F': ' '{print $2}' | xargs)
            
            # Aggregate results by file
            #results["$file"]="spanner.enabled: ${spanner_enabled:-not found}, spanner.migrations_enabled: ${migrations_enabled:-not found}, spanner.services_enabled: ${services_enabled:-not found}"
            echo "$file,${spanner_enabled:-not found},${migrations_enabled:-not found},${services_enabled:-not found}"
        fi
    done

    # Print the aggregated results
    #for file in "${!results[@]}"; do
    #    echo "$file: ${results[$file]}"
    #done
}

aggregate_yaml_by_project_id() {
    # Check if the directory is provided as an argument; otherwise, use the current directory.
    local dir=${1:-.}

    # Initialize an associative array to store results
    declare -A results

    # Loop through all yaml files in the directory
    for file in "$dir"/*.yaml; do
        if [[ -f "$file" ]]; then
            # Initialize values for each property to "not found"
            local shared_project_id="not found"

            # Find the shared_project_id value
            shared_project_id=$(grep -E '^\s*shared_project_id:' "$file" | awk -F': ' '{print $2}' | xargs)
            echo "$file: ${shared_project_id:-not found}"

            # Use shared_project_id as the key to group files
            #results["$shared_project_id"]+="$file"$'\n'
        fi
    done

    # Print the aggregated results grouped by shared_project_id
    #for project_id in "${!results[@]}"; do
        #echo "shared_project_id: ${project_id:-'not found'}"
        #echo "${results[$project_id]}"
        #echo
    #done
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

# Function to rename all .yaml files in a directory to .tpl.yaml
#
# Usage: rename_yaml_to_tpl <directory_path>
#
# Arguments:
#   directory_path: The path to the directory where the renaming should occur.
#                   If no directory is provided, the current directory is used.
function rename_yaml_to_tpl() {
    local target_dir="${1:-.}" # Use provided directory or current directory if none given

    # Check if the target directory exists
    if [[ ! -d "$target_dir" ]]; then
        echo "Error: Directory '$target_dir' not found."
        return 1
    fi

    echo "Searching for .yaml files in '$target_dir'..."

    # Find all .yaml files in the target directory (and its subdirectories)
    # and rename them.
    # -type f: Only considers regular files.
    # -name "*.yaml": Matches files ending with .yaml.
    # -print0: Prints the full file name on the standard output, followed by a null character.
    #          This is safer for file names with spaces or special characters.
    # xargs -0: Reads null-separated items from standard input.
    # mv: Moves (renames) the file.
    # -- "$file": Ensures that filenames starting with '-' are handled correctly.
    # "${file%.yaml}.tpl.yaml": This is parameter expansion to perform the renaming.
    #                           ${file%.yaml} removes the shortest match of .yaml from the end of $file.
    #                           Then, .tpl.yaml is appended.
    find "$target_dir" -type f -name "*.yaml" -print0 | while IFS= read -r -d $'\0' file; do
        # Construct the new filename
        new_file="${file%.yaml}.tpl.yaml"

        # Perform the rename operation
        if mv -- "$file" "$new_file"; then
            echo "Renamed: '$file' -> '$new_file'"
        else
            echo "Error: Failed to rename '$file'."
        fi
    done

    echo "Renaming process complete."
}

