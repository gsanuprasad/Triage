# Jira Triage Cloud Automation — Overnight

Schedules the `jira-triage` skill every **15 minutes from 10:00 PM Australia/Sydney**, continuing through the early morning (including a few runs after 7:00 AM).

This is a **second** automation alongside the daytime 8 AM–6 PM schedule. Same skill, same prompt, different hours.

## Schedule (single cron)

```
CRON_TZ=Australia/Sydney */15 22-23,0-7 * * *
```

| Window (Sydney) | Fires |
|---|---|
| 22:00–23:45 | every 15 minutes |
| 00:00–07:45 | every 15 minutes |

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

- Keep the daytime automation as-is; this overnight automation does not replace it.
- Pull-request tools stay disabled; triage only touches Jira.
- If Atlassian tools are missing at runtime, remove and re-add the MCP entry named exactly `Atlassian`.
- Weekday-only? Change the cron day-of-week field from `*` to `1-5`.
