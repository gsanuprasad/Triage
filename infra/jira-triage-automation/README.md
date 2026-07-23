# Jira Triage Cloud Automation

Schedules the `jira-triage` skill every **15 minutes from 8:00 AM to 6:00 PM Australia/Sydney**.

## Schedule

| Cron | Fires |
|---|---|
| `CRON_TZ=Australia/Sydney */15 8-17 * * *` | :00, :15, :30, :45 from 08:00–17:45 Sydney |
| `CRON_TZ=Australia/Sydney 0 18 * * *` | 18:00 Sydney |

Timezone is handled by `CRON_TZ` (AEDT/AEST). Cron defaults to UTC without that prefix.

## Create via Terraform (recommended)

1. Create a Cursor API key: [Dashboard → API Keys](https://cursor.com/dashboard?tab=integrations)
2. Apply:

```bash
cd infra/jira-triage-automation
export CURSOR_TOKEN='key_...'   # or crsr_...
terraform init
terraform apply
```

3. Open the printed `automation_url`.
4. Under **Tools → MCP**, confirm **Atlassian** is listed (capital **A**).
5. Authenticate Atlassian on that MCP row if prompted, then run a **Test run**.

## Create via UI (manual)

1. Open https://cursor.com/automations/new
2. **Name:** `Jira Triage — SD`
3. **Trigger → Scheduled → Custom cron**, add both expressions above
4. **Prompt:** paste contents of [`prompt.md`](./prompt.md)
5. **Repository:** `gsanuprasad/triage`, branch `master` (required so the skill loads)
6. **Tools → MCP:** enable **Atlassian** (exact casing)
7. Do **not** enable pull-request creation
8. Permissions: Team Visible (runs as you — keeps your Atlassian OAuth)
9. Save and activate

## Notes

- Pull-request tools stay disabled; triage only touches Jira.
- If Atlassian tools are missing at runtime, remove and re-add the MCP entry named exactly `Atlassian`.
- Weekday-only? Change both cron day-of-week fields from `*` to `1-5`.
