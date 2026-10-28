# Commits & Pull Requests

How David wants commits written and pull requests opened.
Read this when committing or opening/editing a PR.

## Commit messages

- NEVER auto-add the agent as a co-author or sign-off (no "Generated with", no "Co-Authored-By"). This is a hard rule.
- Prefer one- or two-line messages.

## PR description template

Open with a 1–2 line high-level summary, then just enough to understand the problem and the solution.
Avoid excessive detail — people won't read a wall of text.

```markdown
<1–2 line summary: what this change does and why.>

## Intent
<What was wrong or needed — enough context to understand, no wall of text.>

## What Changed
<The approach taken; call out anything non-obvious or worth a reviewer's attention.>

## Risk Assessmet
<How risky are these code changes? Choose one of Low, Medium, High, and justify the choice.>

## Testing
<How the code was tested, including evidecne of success.>

## Pipline
<Optional log of actions required to get or keep the CI pipeline green and ready to merge.>
```

## Editing a PR description

Edit descriptions with this style:
`gh api repos/CyberhavenInc/dataflow/pulls/<pr_number> -X PATCH -f body='...'`

## Replying to review comments

Only reply to comments when directed.

Never edit an existing comment. Always reply:
- General PR comment: `gh pr comment <pr_number> --body "..."`
- Reply to a specific review comment: `gh api repos/<owner>/<repo>/pulls/<pr_number>/comments -X POST -f body="..." -f in_reply_to=<comment_id>`

## Cyberhaven specifics

- Run Go linting before committing: e.g. `cd /Users/driott/code/dataflow/backend && make lint-folder path=apps/dlp-categorizer/governor 2>&1`.
