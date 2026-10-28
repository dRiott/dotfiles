# AI Conversation Lineage Reference Design

## Purpose

Improve future production-data investigations involving AI conversations, content classification, edge lineage, and label propagation.
The documentation must help an agent distinguish direct content classification from conversation-level or location-level labels.
It must also provide a repeatable method to identify the exact content that introduced a label.

## Scope

This change updates `cyberhaven/infra-reference.md` with a short set of essential rules.
It also creates `cyberhaven/ai-conversation-lineage.md` as the detailed investigation runbook.
The existing reference from `AGENTS.md` to `cyberhaven/infra-reference.md` remains the entry point.

## Infrastructure Reference Changes

Add an `AI Conversation Lineage` section to `cyberhaven/infra-reference.md`.
The section will instruct agents to separate direct SHA classifications, synthetic conversation classifications, location labels, and edge labels.
It will warn that a UI card or conversation-facing edge does not prove that the displayed SHA matched a rule.
It will identify event time, scan time, location-version time, and postprocessor time as separate clocks.
It will warn that asynchronous processing can apply later conversation state to an earlier event's conversation-facing edge.
It will distinguish `data/pattern` policy labels from matched `data/type` classifications.
It will direct agents to read `~/.config/cyberhaven/ai-conversation-lineage.md` for the complete workflow.

## Detailed Runbook

The new runbook will contain the following sections:

1. Scope and investigation goals.
2. A data model for SHA-addressed content, synthetic conversation content, locations, location versions, direct edges, and lineage edges.
3. An evidence hierarchy that treats Spanner `content_scan_rule` rows for a SHA as the strongest evidence of direct classification.
4. A workflow to find the conversation, enumerate every associated content SHA, query direct scan results, find the earliest true match, and compare processing timelines.
5. BigQuery templates for `edges` and `location_versions`.
6. Spanner templates for `content_scan` and `content_scan_rule`.
7. GCS recovery and SHA-256 verification guidance.
8. Guidance for handling duplicate append-only edge rows and asynchronous enrichment.
9. Common misleading signals and investigation failure modes.
10. Read-only access and Kubernetes-context safety rules.
11. Artifact and reporting conventions for reproducible investigations.

## Safety and Accuracy

The runbook will use read-only commands.
It will require explicit Kubernetes context arguments when Kubernetes access is necessary.
It will prohibit changing the default context during an investigation.
It will advise agents to preserve raw query output and downloaded content by SHA.
It will clearly mark dogfood service accounts and resource names as environment-specific examples.
It will tell agents to inspect the current schema before assuming that fields such as `labels` or `label_ids` have the same shape in every dataset.

## Success Criteria

A future agent can start with a conversation ID or SHA and produce a complete content manifest.
The agent can determine whether a label came from direct SHA classification or conversation propagation.
The agent can identify the first directly matched content and reconstruct the causal timeline.
The agent avoids treating UI labels, policy labels, or enriched edge labels as proof of a direct match.
The agent leaves the active Kubernetes context unchanged.
