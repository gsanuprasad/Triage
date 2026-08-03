---
name: jira-leave-check
description: Report which Baseplan staff are on leave or otherwise out of office for a given period, using approval tickets in the Jira Approvals (AP) project. Use this skill whenever the user asks "who is on leave", "who's on leave this week", "who is away today", "who's out next week", "is <person> on leave", "leave calendar", "who is out of office", or asks for team availability for a date or date range. Always match leave by date-range overlap (not start date alone) and always treat the Reporter as the person on leave.
---

# Jira Leave Check — Baseplan Approvals (AP)

This skill answers "who is on leave?" for any date or date range by querying leave and out-of-office approval tickets in the **Approvals (AP)** Jira project.

## Jira Connection Details

- **Cloud ID**: `47ce615b-398d-4e09-99f5-d0c64b17b2a5`
- **Site**: `https://baseplanhelpdesk.atlassian.net`
- **Project**: `AP` (Approvals, project ID `14136`)
- **Default timezone for "today" / "this week"**: `Australia/Sydney`

## Two critical rules

These are the two mistakes that produce wrong answers. Apply both every time.

1. **Match on overlap, never on start date alone.** Someone whose leave started last month and ends next month *is* on leave this week. Filter with `From <= period_end AND To >= period_start`.
2. **The Reporter is the person on leave.** The Assignee is the approving manager, not the person taking leave. See [Identifying the person on leave](#step-3--identify-the-person-on-leave).

## Leave issue types and their date fields

The AP project uses **two different pairs of date fields** depending on issue type. A query that only uses `Leave Date From`/`To` silently misses all travel absences, so run both queries.

### Group A — Leave types (use `Leave Date From` / `Leave Date To`)

| Issue type | ID | Field: From | Field: To |
|---|---|---|---|
| Annual Leave | 10806 | `customfield_22525` | `customfield_22526` |
| Sick Leave | 10809 | `customfield_22525` | `customfield_22526` |
| Carers Leave | 10807 | `customfield_22525` | `customfield_22526` |
| Leave Without Pay | 10805 | `customfield_22525` | `customfield_22526` |
| LSL (Long Service Leave) | 10801 | `customfield_22525` | `customfield_22526` |
| Time In Lieu | 10804 | `customfield_22525` | `customfield_22526` |

### Group B — Travel types (use `Travel From` / `Travel To`)

| Issue type | ID | Field: From | Field: To |
|---|---|---|---|
| Travel - out of office | 10601 | `customfield_22529` | `customfield_22524` |
| Travel - To BPNA | 10808 | `customfield_22529` | `customfield_22524` |

Travel means the person is **out of the office but normally still working**. Label these as "Travelling / out of office", not "on leave", and keep them in a separate section from actual leave so the reader can tell who is contactable.

### Not absence types — always exclude

`Expenses` (10800), `Purchase Requisition` (10802), `Overtime` (10803), `New Staff` (10810). These have no leave dates and must never appear in the report.

## Step 1 — Resolve the date range

Convert the user's request into an explicit `period_start` and `period_end` (inclusive, `YYYY-MM-DD`), using **Australia/Sydney** as the reference timezone.

| User says | Range |
|---|---|
| "today" | today → today |
| "tomorrow" | tomorrow → tomorrow |
| "this week" | Monday of the current week → Sunday of the same week |
| "next week" | Monday of next week → Sunday of next week |
| "this month" | 1st → last day of the current month |
| "the 12th" / a single date | that date → that date |
| an explicit range | as given |

Notes:
- "This week" means the **calendar week containing today (Monday–Sunday)**, not the next seven days. If today is Monday 3 Aug 2026, the range is `2026-08-03` → `2026-08-09`.
- Always state the resolved range in the answer so the user can confirm the interpretation.

## Step 2 — Run both overlap queries

Run these two `searchJiraIssuesUsingJql` calls. They can be run in parallel.

**Query A — leave types:**

```
project = AP AND "Leave Date From" <= "<period_end>" AND "Leave Date To" >= "<period_start>" ORDER BY "Leave Date From" ASC
```

**Query B — travel types:**

```
project = AP AND "Travel From" <= "<period_end>" AND "Travel To" >= "<period_start>" ORDER BY "Travel From" ASC
```

Request these fields on both: `summary`, `status`, `issuetype`, `reporter`, `assignee`, `description`, `customfield_22525`, `customfield_22526`, `customfield_22529`, `customfield_22524`, `customfield_21636`.

Set `maxResults` to 100. If the response indicates more pages, follow `nextPageToken` until `isLast` is true — never report a partial list.

Do not add an `issuetype in (...)` clause. The date-field filters already restrict results to absence types, and hardcoding the type list means new leave types are silently dropped.

## Step 3 — Identify the person on leave

**The Reporter is the person on leave. The Assignee is the approving manager.**

Staff raise their own leave request and assign it to their manager for approval. In this instance almost all requests are assigned to the approver **Anu Prasad**, and Anu's own leave requests are assigned to **Kate Everitt**. So a ticket reported by Anu Prasad and assigned to Kate Everitt is **Anu's** leave, not Kate's.

Never infer the person from the Assignee. Do not treat a frequent approver appearing as Reporter as a data error — approvers take leave too.

Only override the Reporter when the summary or description **explicitly names a different person** as the one taking leave (e.g. "Request for day off for Phil" raised by an assistant). In that case use the named person and note in the output that the ticket was raised on their behalf.

## Step 4 — Classify by approval status

The AP workflow uses these statuses:

| Status | ID | Meaning | Include in report? |
|---|---|---|---|
| `Done` | 10003 | Approved | Yes — main list |
| `Under Review` | 10500 | Awaiting manager approval | Yes — list separately as pending |
| `Rejected` | 10503 | Not approved | No — exclude from the "on leave" list |

Report approved absences as the answer. List `Under Review` items in a separate "Pending approval" section, since those people may or may not end up away. Exclude `Rejected` entirely — a rejected request means the person is **at work**.

If a status appears that is not in this table, include the item and flag the unrecognised status rather than guessing.

## Step 5 — Report

Lead with a direct answer, then a table. For each person include: name, absence type, dates, which days of the requested period they are actually away, status, and ticket link.

Formatting rules:
- Clip the displayed dates to the requested period when the absence extends beyond it, but also show the person's full absence range so the reader knows they are away either side.
- For a single-day absence, show the day name (e.g. "Thu 6 Aug").
- Link tickets as `https://baseplanhelpdesk.atlassian.net/browse/AP-XXXX`.
- Sort by start date, then by name.
- If nobody is away, say so plainly: "No one has approved leave for <range>." Still report anything pending approval.

Suggested shape:

```
Who's on leave this week (3–9 Aug 2026):

| Person | Type | Dates | Status | Ticket |
|---|---|---|---|---|
| William Wright | Annual Leave | Mon 3 – Fri 7 Aug | Approved | AP-6932 |
| Tommy Rubelj | Time In Lieu | Mon 3 Aug | Approved | AP-6921 |
| Anu Prasad | Time In Lieu | Thu 6 Aug | Approved | AP-7031 |
```

That example is a real result for 3–9 Aug 2026 and is a useful self-check: AP-7031 is reported by Anu Prasad and assigned to Kate Everitt, and the person on leave is **Anu**. If a run of this skill reports Kate Everitt for that ticket, step 3 has been applied backwards.

## Scope and caveats

State these only when they actually affect the answer:

- This reports only what is recorded in the AP project. Leave logged in Workday (US team) or Multiplier (India team) but not raised in Jira will not appear.
- Public holidays are not tracked in AP and are not included.
- Partial-day absences (e.g. half-day sick leave) are recorded as a single-day range; the hours are usually only in the description. Mention a partial day if the description says so.

## Answering "is <person> on leave?"

For a question about one person, run the same two queries for the period, then filter by Reporter display name or email (`firstname.lastname@baseplan.com`). If they have nothing in the range, answer that they have no leave booked for that period — and say what was searched, so the absence of a record is not mistaken for a confirmed presence.
