# Atlassian MCP setup for SD Jira Triage (Cloud Automations)

The triage skill calls Atlassian/Jira MCP tools. Those tools are **not** loaded from the repo, `.cursor/mcp.json`, or team/user MCP toggles alone. They must be attached on the automation itself.

**Automation:** [SD Jira Triage](https://cursor.com/automations/801a2155-817e-11f1-a7d1-d6b4613131ce)  
**Owner:** Anu Prasad (`anu.prasad@baseplan.com`)

## Symptom

A cloud automation run’s MCP catalog shows only:

- `Cursor Automation Tools`
- `cursor-cloud`

…and **no** Atlassian/Jira server. Triage cannot fetch or edit SD issues.

## Fix (owner or team admin — Cursor UI only)

### 1. Register Atlassian as Team HTTP MCP

1. Open [Dashboard → Integrations & MCP](https://cursor.com/dashboard/integrations)
2. Add Atlassian as an **HTTP** MCP server (not stdio, not `mcp-remote` / SSE)
3. URL: `https://mcp.atlassian.com/v1/mcp/authv2`
4. Complete **OAuth** when prompted (Atlassian consent)

Cloud Agents support **HTTP or stdio only**. Do not use SSE or `npx mcp-remote …`.

### 2. Attach Atlassian to the automation (required)

1. Open [SD Jira Triage](https://cursor.com/automations/801a2155-817e-11f1-a7d1-d6b4613131ce)
2. Edit → **Tools**
3. **Add Tool or MCP** → **MCP Server**
4. Select the existing Atlassian team connection, **or** create a new connection with the same HTTP URL and finish OAuth
5. Confirm Atlassian appears in the automation’s tool list
6. **Save**

Team/user Agents MCP dropdown “enabled” is **not** enough. The server must appear under this automation’s Tools.

### 3. Verify

1. Trigger a new run (or wait for the next cron)
2. Confirm the run can discover Atlassian tools (e.g. Jira search / issue edit), not only Automation Tools and cursor-cloud
3. Confirm triage can run JQL: `project = SD AND status = "Triage" ORDER BY created ASC`

## Permissions / identity notes

| Case | Action |
|---|---|
| Private / Team Visible | Creator manages tools; OAuth is for that user |
| Promoted to **Team Owned** | Runs as the team automations service account — re-auth Atlassian MCP for that service account; personal OAuth does not carry over |
| Who can edit Team Owned | Team admins only |

## What cannot fix this

- Repo files, skills, or `environment.json`
- IDE / local `.cursor/mcp.json`
- Enabling Atlassian only on the team or user MCP dropdown without attaching it under the automation’s Tools
- Using the built-in [Cursor ↔ Jira](https://cursor.com/docs/integrations/jira.md) integration instead of Atlassian MCP (different product path)

## Docs

- [Automations → Tools → MCP server](https://cursor.com/docs/cloud-agent/automations.md)
- [Cloud agent capabilities → MCP tools](https://cursor.com/docs/cloud-agent/capabilities.md#mcp-tools)
- [MCP overview](https://cursor.com/docs/mcp.md)
