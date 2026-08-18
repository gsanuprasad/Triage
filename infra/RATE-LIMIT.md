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

## Immediate recovery (do this first)

1. Open [Cloud Agents](https://cursor.com/agents).
2. Filter to this repo (`gsanuprasad/Triage`) and status **Idle**.
3. **Archive** old completed/idle runs (`Sd project triage`, `Sd issues triage`, `Jira SD project triage`). Leave only a current run if one is actually working.
4. Confirm no other personal/team cloud agents are **Running** (other repos count toward the same cap).
5. Open [Jira Triage — SD](https://cursor.com/automations/71809cde-8651-11f1-a7d1-d6b4613131ce) → **Test run** (or wait for the next cron).
6. If it still rate-limits, wait 10–15 minutes after archiving and retry, or ask a team admin to check on-demand usage. Cursor support: `hi@cursor.com`.

Archiving is the unblock. Do not keep hitting Play while the error is showing — that makes the cap worse.

## Durable fix: slow the cron (required)

Edit both automations in the Cursor UI. Change `*/15` to `*/30`.

**Daytime** — [Jira Triage — SD](https://cursor.com/automations/71809cde-8651-11f1-a7d1-d6b4613131ce)

```
CRON_TZ=Australia/Sydney */30 8-18 * * 1-6
```

**Overnight** — [Jira Triage — SD Overnight](https://cursor.com/automations/13ac9789-8a13-11f1-b532-320a589b8025)

```
CRON_TZ=Australia/Sydney */30 22-23,0-7 * * *
```

After saving, Terraform for overnight should match (`infra/jira-triage-automation-overnight`). Daytime is UI-only unless you import it later.

30 minutes still covers new SD tickets promptly and cuts cloud-agent starts roughly in half (~42/day instead of ~84). If rate limits return, switch both to `0 *` (hourly).

## Avoid stacking extra agents

- Do not start a desktop/cloud investigation agent during the daytime cron window unless you have spare concurrent slots.
- Do not enable a third triage automation.
- Triage prompts must **not** launch subagents / parallel cloud agents (`Task` tool). One sequential run per tick.
- Cursor skips a *scheduled* tick if that same automation still has a run in progress. Manual **Play** does not skip — never Play while a run is active.

## If it keeps failing after archive + 30-minute cron

1. Check [Cursor dashboard usage](https://cursor.com/dashboard) — team on-demand budget at 100% also blocks automations.
2. Recreate the daytime automation (stale “still running” records can skip all future crons; [forum](https://forum.cursor.com/t/cursor-automations-stopped-running-on-hourly-schedule/155679)).
3. Ask Cursor support to inspect automation `71809cde-8651-11f1-a7d1-d6b4613131ce` and raise the concurrent cloud-agent limit.
