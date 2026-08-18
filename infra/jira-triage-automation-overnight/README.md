# Jira Triage Cloud Automation — Overnight

Schedules the `jira-triage` skill every **30 minutes from 10:00 PM Australia/Sydney**, continuing through the early morning (including a run at 7:30 AM).

This is a **second** automation alongside the daytime 8 AM–6 PM schedule. Same skill, same prompt, different hours.

A 15-minute cadence creates too many cloud agents and trips Cursor's concurrent-run rate limit. See [`../RATE-LIMIT.md`](../RATE-LIMIT.md).

## Schedule (single cron)

```
CRON_TZ=Australia/Sydney */30 22-23,0-7 * * *
```

| Window (Sydney) | Fires |
|---|---|
| 22:00–23:30 | every 30 minutes |
| 00:00–07:30 | every 30 minutes |

Timezone is handled by `CRON_TZ` (AEDT/AEST). Cron defaults to UTC without that prefix.

## Create via UI (recommended if daytime automation was created manually)

1. Open https://cursor.com/automations/new
2. **Name:** `Jira Triage — SD Overnight`
3. **Trigger → Scheduled → Custom cron**, paste the **one** expression above
4. **Prompt:** paste contents of [`prompt.md`](./prompt.md)
5. **Repository:** `gsanuprasad/triage`, branch `master` (required so the skill loads)
6. **Tools → MCP:** enable **Atlassian** (exact casing)
7. Do **not** enable pull-request creation
8. Permissions: Team Visible (runs as you — keeps your Atlassian OAuth)
9. Save and activate

## Create via Terraform

1. Create a Cursor API key: [Dashboard → API Keys](https://cursor.com/dashboard?tab=integrations)
2. Apply:

```bash
cd infra/jira-triage-automation-overnight
export CURSOR_TOKEN='key_...'   # or crsr_...
terraform init
terraform apply
```

3. Open the printed `automation_url`.
4. Under **Tools → MCP**, confirm **Atlassian** is listed (capital **A**).
5. Authenticate Atlassian on that MCP row if prompted, then run a **Test run**.

## Notes

- Keep the daytime automation as a separate schedule; this overnight automation does not replace it. Daytime cron must also use `*/30` (not `*/15`) — see [`../RATE-LIMIT.md`](../RATE-LIMIT.md).
- Pull-request tools stay disabled; triage only touches Jira.
- If Atlassian tools are missing at runtime, remove and re-add the MCP entry named exactly `Atlassian`.
- Weekday-only? Change the cron day-of-week field from `*` to `1-5`.
