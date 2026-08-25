---
name: fix-merge-cancelled-to-done
description: Fix ENT Jira issues (especially Merge Tasks) that Automation incorrectly resolved as Cancelled — update resolution to Done while leaving status Closed. Use when the user says "fix cancelled merge tasks", "set cancelled to done", "fix merge resolution", "cancelled instead of done", or asks to correct Cancelled resolution on Merge Tasks / Bugs / Modifications in ENT.
---

# Fix Cancelled → Done (ENT Merge Tasks)

Automation for Jira sometimes closes ENT work as **Closed** with resolution **Cancelled**, even when the work completed successfully (often after briefly setting **Done**). This skill corrects those issues by setting resolution to **Done** without changing status.

## When to use

- Merge Tasks (default), or Bugs / Modifications when the user includes them
- Resolution is **Cancelled** but the summary is **not** intentionally cancelled
- User wants bulk correction after automation mistakes

## Jira connection

| Item | Value |
|---|---|
| Cloud ID | `47ce615b-398d-4e09-99f5-d0c64b17b2a5` |
| Project | `ENT` |
| Done resolution ID | `10000` |
| Cancelled resolution ID | `10103` |

Use Atlassian MCP tools: `searchJiraIssuesUsingJql`, `editJiraIssue`, `getJiraIssue`.

## Default JQL

```
project = ENT
AND type = "Merge Task"
AND resolution = Cancelled
AND resolutiondate > -50d
AND summary !~ CANCELLED
ORDER BY resolutiondate DESC
```

### Expand when the user asks

- **Include Bugs / Modifications** (as used in prior runs):

```
project = ENT
AND type in (Bug, Modification, "Merge Task")
AND resolution = Cancelled
AND resolutiondate > -50d
AND summary !~ CANCELLED
ORDER BY resolutiondate DESC
```

- **Assignee filter** — add `AND assignee = <accountId>` only if the user specifies one.
- **Date window** — change `resolutiondate > -50d` if the user gives a different range.
- **Exclude intentional cancels** — always keep `summary !~ CANCELLED` unless the user explicitly wants those too.

Request fields: `summary`, `status`, `resolution`, `issuetype`, `assignee`, `resolutiondate`.

Paginate if needed (`maxResults` up to 100; follow `nextPageToken` until `isLast`).

## Critical rule: edit resolution directly — do NOT use the Cancelled transition

**Do not** call `transitionJiraIssue` with the global **Cancelled** transition (`id: 161`).

That transition closes to **Closed** and has a Resolution screen, but a workflow post-function / automation **overwrites** the chosen resolution back to **Cancelled**. Passing `resolution = Done` on that transition does **not** stick.

**Correct method** — `editJiraIssue`:

```json
{
  "cloudId": "47ce615b-398d-4e09-99f5-d0c64b17b2a5",
  "issueIdOrKey": "ENT-XXXXX",
  "fields": {
    "resolution": { "id": "10000" }
  }
}
```

Status stays **Closed**. Resolution becomes **Done**.

Direct edit works even when `resolution` is absent from `editmeta` on closed issues.

## Workflow

### 1. Confirm scope before changing (unless user already said to proceed)

1. Run the JQL and report:
   - Total count
   - Breakdown by issue type
   - Sample keys (or full list if ≤ ~20)
2. Ask for confirmation if the user has not already approved (e.g. first run in the conversation).
3. Do **not** edit until confirmed, unless the user already said "yes", "do all", "run the same update", etc.

### 2. Apply updates

For each matching key, call `editJiraIssue` with `resolution.id = "10000"`.

- Batch in parallel (about 15–20 at a time) for large sets.
- Treat each response's `fields.resolution.name === "Done"` as success for that key.
- Collect failures (key + error) and retry once; report any remaining failures.

### 3. Verify

1. Re-run the same Cancelled JQL — expect **0** (or only intentional leftovers).
2. Optionally confirm the updated keys:  
   `key in (...) AND resolution = Done` — count should match successful edits.
3. Spot-check one issue changelog if something looks wrong: look for resolution `Cancelled` → `Done` from the edit (not a Cancelled transition).

### 4. Report

Tell the user:

- How many updated
- Type breakdown (e.g. Merge Task / Bug)
- That status remained Closed
- Any failures
- That the Cancelled filter is now empty (or what remains)

## Do not

- Re-open then re-close (unnecessary; status is already Closed)
- Use transition `161` (Cancelled) hoping to set Done
- Change issues whose summary contains `CANCELLED` unless the user opts in
- Change resolution on issues that are not Closed / Cancelled unless the user asks
- Create comments or other field changes unless asked

## Background (why Cancelled appears)

On affected issues, changelog often shows Automation for Jira:

1. Set resolution **None → Done**
2. Almost immediately set status to **Closed** and resolution **Done → Cancelled**

This skill only corrects the resolution field; fixing the automation rule itself is out of scope unless the user asks.
