# Jira triage: "Rate limited" / too many concurrent runs

Cursor cloud automations create a **new cloud agent on every cron tick**. Cursor caps how many cloud agents can run at once (about **8 on Pro**; Team/Ultra are higher). When the cap is hit, scheduled triage fails with:

> The run was rate-limited due to too many concurrent runs. Retry after a short delay or reduce the number of parallel runs.

This is a **Cursor platform limit**, not a Jira API limit. Failed ticks usually never create an agent, so they show only on the automation run summary.

## What happened on 18 Aug 2026

| Window (Sydney) | What ran |
|---|---|
| Overnight 00:00–07:45 | `Jira Triage — SD Overnight` every 15 minutes — all succeeded |
| Daytime 08:00–10:15 | `Jira Triage — SD` every 15 minutes — all succeeded |
| **10:30–11:45** | Daytime cron kept firing; **every tick was rate-limited** (~2 hours) |
| 12:00 onwards | Daytime runs succeeded again |

Two automations fire about **84 cloud agents per weekday** at a 15-minute cadence. After each run the agent stays **IDLE** (not archived). Cursor has repeatedly counted stale IDLE agents toward the concurrent cap ([forum](https://forum.cursor.com/t/cloud-agents-simultaneous-limit-what-are-the-actual-numbers-per-plan/154013)).

## How to see the idle triage agents (they are hidden by default)

The ~199 figure is **not** shown as a badge on the Automations run summary. Each successful cron tick creates a finished cloud agent named `Sd project triage` or `Sd issues triage`. The API calls that state **IDLE** (finished, VM still listed). The web UI has **no “Idle” filter**, and **Automations-sourced agents are hidden** until you turn that source on — same pattern as [SDK runs](https://cursor.com/docs/sdk/typescript.md#creating-agents).

Do **not** look at:

- The automation **Run summary** (that list is cron ticks; rate-limited ticks never become agents)
- [Dashboard → Cloud Agents](https://cursor.com/dashboard/cloud-agents) (environments/settings, not the run list)
- The desktop editor chat sidebar (only a short window of interactive chats)

**View them:**

1. Open [https://cursor.com/agents](https://cursor.com/agents) in the browser (not the dashboard).
2. In the sidebar, try **My agents**, then **Team agents** (Automations are Team Visible; some lists split ownership).
3. Click **Filter → Source** and enable **Automations** (also enable **API** / **SDK** if those toggles exist). Cursor hides non-interactive sources by default.
4. Optionally filter the repo to `gsanuprasad/Triage`. Names look like `Sd project triage`, `Sd issues triage`, `SD project issue triage`.
5. Scroll / page — the list is newest-first and paginated. There is no “199 idle” counter.

Direct examples from this morning (Sydney), still unarchived:

- [12:30 run](https://cursor.com/agents/bc-a4a39dac-39d1-403a-a7c9-e15b92d85463)
- [12:15 run](https://cursor.com/agents/bc-93241c27-48b4-4877-adee-d33a2af55837)
- [12:00 run](https://cursor.com/agents/bc-089e5cfa-9de1-47e2-8659-3b2daef3dfed)

You can also open a run from the automation’s history: click a **Succeeded** row (not a Rate limited row) → it opens that agent.

## Archive (one at a time in the UI)

There is **no bulk archive** for cloud agents in the UI. Archive is per agent and reversible.

1. Open an agent from the filtered list or a direct URL above.
2. Use the **⋯** (or overflow) menu → **Archive**. That hides it from the active list and stops the run.
3. Repeat for old finished triage conversations. Skip anything still **Running**.

Permanent delete is API-only (`DELETE https://api.cursor.com/v1/agents/{id}`). Archive is `POST https://api.cursor.com/v1/agents/{id}/archive` — loop that if you need to clear hundreds.

After archiving, run a **Test run** on the daytime automation (or wait for the next cron). If it still rate-limits, wait 10–15 minutes and retry, or ask a team admin to check on-demand usage (`hi@cursor.com`).

Archiving is a workaround Cursor staff recommended when stale finished agents were counted toward the cap. Do not keep hitting Play while the error is showing.

## Keep the 15-minute cron (SLA)

Do **not** slow the schedule. Daytime and overnight stay at `*/15` so new SD tickets can be triaged within the SLA window.

**Daytime** — [Jira Triage — SD](https://cursor.com/automations/71809cde-8651-11f1-a7d1-d6b4613131ce)

```
CRON_TZ=Australia/Sydney */15 8-18 * * 1-6
```

**Overnight** — [Jira Triage — SD Overnight](https://cursor.com/automations/13ac9789-8a13-11f1-b532-320a589b8025)

```
CRON_TZ=Australia/Sydney */15 22-23,0-7 * * *
```

To keep `*/15` without another 2-hour gap:

1. Do not start extra desktop/cloud investigation agents during 8 AM–6 PM Sydney unless a triage tick is allowed to fail.
2. Triage runs must stay sequential (no Task/subagents) — already in the overnight prompt and skill.
3. Never **Play** an automation while a tick is still running. Cursor skips a *scheduled* overlap; manual Play does not.
4. If the cap hits again, archive old finished Automations agents (above) or ask Cursor support (`hi@cursor.com`) to raise the concurrent cloud-agent limit for this team. Name automation `71809cde-8651-11f1-a7d1-d6b4613131ce` and the SLA need for 15-minute ticks.

## Avoid stacking extra agents

- Do not start a desktop/cloud investigation agent during the daytime cron window unless you have spare concurrent slots.
- Do not enable a third triage automation.
- Triage prompts must **not** launch subagents / parallel cloud agents (`Task` tool). One sequential run per tick.
- Cursor skips a *scheduled* tick if that same automation still has a run in progress. Manual **Play** does not skip — never Play while a run is active.

## If it keeps failing at 15 minutes

1. Check [Cursor dashboard usage](https://cursor.com/dashboard) — team on-demand budget at 100% also blocks automations.
2. Recreate the daytime automation (stale “still running” records can skip all future crons; [forum](https://forum.cursor.com/t/cursor-automations-stopped-running-on-hourly-schedule/155679)).
3. Ask Cursor support to inspect automation `71809cde-8651-11f1-a7d1-d6b4613131ce` and raise the concurrent cloud-agent limit.
