# Tools

Reference for tools and how David likes to use them.
Lazy-loaded — read the relevant section when working with one of these tools.

> Tool preferences below are starting points; edit freely.

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

## superpowers
Skill framework: invoke a skill via the `Skill` tool before acting when one applies; never `Read` skill files directly.
Priority is explicit: David's instructions (CLAUDE.md/AGENTS.md) > skills > default behavior — skills do not override a direct instruction.
Process skills (brainstorming, debugging, TDD) come before implementation skills.

## ponytail
Lazy-senior-dev coding mode: laziest solution that actually works, default level **full**.
Climb the ladder — does it need to exist? → stdlib → native platform → existing dep → one line → minimal code — and stop at the first rung that holds.
Mark deliberate shortcuts with a `ponytail:` comment naming the ceiling and upgrade path.
Switch levels with `/ponytail lite|full|ultra`; disable with "stop ponytail" / "normal mode".
Never simplify away validation, error handling, security, accessibility, or anything explicitly requested.

## lavish-axi
HTML-artifact review tool — turns a rich/interactive HTML page into a surface David can annotate and send feedback from.
Use when a response is easier to grasp visually (plans, comparisons, diagrams, tables, dashboards).
Workflow: write HTML under `.lavish/`, run `lavish-axi <html-file>`, then `lavish-axi poll <html-file>` (long-polls — leave it running) and fix any reported `layout_warnings` before involving David.

## gh-axi (GitHub)
Agent skill installed at `~/.agents/skills/gh-axi`. Prefer it over raw `gh` for GitHub operations (issues, PRs, CI runs, workflows, releases, repos, labels, search, raw API).
Invoke with `npx -y gh-axi <command>` — no global install needed; npx resolves it on demand.
Requires the `gh` CLI installed and authenticated (`gh auth login`); if a command fails on auth, ask David to run `gh auth login`.
Run `npx -y gh-axi` with no args for a repo dashboard; target another repo with `-R owner/name` placed AFTER the command.
PR description / review-reply etiquette lives in the **Pull Requests** section of `~/.config/AGENTS.md`.

## Other tooling
<!-- Add new tool preferences here so they stay lazy-loaded with the rest. -->
