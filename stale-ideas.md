## lavish-axi
HTML-artifact review tool — turns a rich/interactive HTML page into a surface David can annotate and send feedback from.
Use only when asked (prefer static HTML resources), but can be used when response is easier to grasp visually (plans, comparisons, diagrams, tables, dashboards).
Workflow: write HTML under `.lavish/`, run `lavish-axi <html-file>`, then `lavish-axi poll <html-file>` (long-polls — leave it running) and fix any reported `layout_warnings` before involving David.

## No-mistakes (GitHub https://github.com/kunchenguid/no-mistakes)
no-mistakes puts a local git proxy in front of your real remote. Push to no-mistakes instead of origin, and it spins up a disposable worktree, runs an AI-driven validation pipeline, forwards the branch to the configured push target only after every check passes, and opens a clean PR automatically.
Full documentation (only if required for troubleshooting): https://kunchenguid.github.io/no-mistakes/

Three ways to trigger the gate
- git push no-mistakes - the explicit Git path. Push a committed branch to the gate remote instead of origin.
- no-mistakes - the TUI. Run it after making changes (no commit needed) and a wizard walks you through creating a branch, committing, and pushing through the gate, then attaches to the run. no-mistakes -y does all of that automatically.
- /no-mistakes - the agent skill. Tell the coding agent to do a task and gate it with /no-mistakes <task>, or use bare /no-mistakes to gate existing committed work. It runs the pipeline, has the pipeline apply safe fixes, and stops to ask you about anything that needs a human call.

