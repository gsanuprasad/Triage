# Jira Triage Cloud Automation — Overnight

Schedules the `jira-triage` skill every **15 minutes from 10:00 PM to 7:00 AM Australia/Sydney**.

This is a **second** automation alongside the daytime 8 AM–6 PM schedule. Same skill, same prompt, different hours.

## Schedule

| Cron | Fires (Sydney) |
|---|---|
| `CRON_TZ=Australia/Sydney */15 22-23 * * *` | 22:00, 22:15, …, 23:45 |
| `CRON_TZ=Australia/Sydney */15 0-6 * * *` | 00:00, 00:15, …, 06:45 |
| `CRON_TZ=Australia/Sydney 0 7 * * *` | 07:00 |

Timezone is handled by `CRON_TZ` (AEDT/AEST). Cron defaults to UTC without that prefix.

## Create via UI (recommended if daytime automation was created manually)

1. Open https://cursor.com/automations/new
2. **Name:** `Jira Triage — SD Overnight`
3. **Trigger → Scheduled → Custom cron**, add **all three** expressions above (each as its own cron trigger)
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

- Keep the daytime automation as-is; this overnight automation does not replace it.
- Pull-request tools stay disabled; triage only touches Jira.
- If Atlassian tools are missing at runtime, remove and re-add the MCP entry named exactly `Atlassian`.
- Weekday-only? Change all three cron day-of-week fields from `*` to `1-5`.
