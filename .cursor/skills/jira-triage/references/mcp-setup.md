# Atlassian MCP setup for SD Jira Triage

Automations do **not** inherit team/user MCP “connected” state. Atlassian must be added on the automation itself.

## Why triage reports Jira unavailable

The agent discovers tools via `GetMcpTools`. If the catalog only shows `Cursor Automation Tools` and `cursor-cloud`, Atlassian is not attached to **this automation run**, even if Team Integrations shows Atlassian as connected.

## Owner checklist

1. **Team Integrations** — Add Atlassian as an HTTP MCP:
   - URL: `https://mcp.atlassian.com/v1/mcp/authv2`
   - Complete OAuth for the account that should access Jira Cloud ID `47ce615b-398d-4e09-99f5-d0c64b17b2a5`
2. Open **[SD Jira Triage](https://cursor.com/automations/801a2155-817e-11f1-a7d1-d6b4613131ce)**
3. Under **Tools → Add Tool or MCP → MCP Server**, select **Atlassian** so it appears in the automation’s tool list (not only in the team dropdown)
4. Ensure the automation is **Enabled**
5. **Save**, then trigger a **new** run (existing runs keep their original tool set)

## Constraints

- Cloud Agents support HTTP or stdio MCP only (not SSE / `mcp-remote`)
- Team Owned automations may need re-auth as the team automations service account
- MCP attach cannot be done from the repo, `environment.json`, or agent code — Cursor UI only
- Owner: Anu Prasad (`anu.prasad@baseplan.com`) or a team admin if Team Owned

## Verify after attach

A successful run’s tool catalog should include Atlassian tools such as `searchJiraIssuesUsingJql`, `getJiraIssue`, `editJiraIssue`, `getTransitionsForJiraIssue`, and `transitionJiraIssue`.
