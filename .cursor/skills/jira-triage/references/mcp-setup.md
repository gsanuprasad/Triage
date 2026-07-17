# Atlassian MCP setup for SD Jira Triage

Cloud Automations only expose MCP servers that are registered for Cloud Agents **and** enabled on the automation. Desktop / repo `mcp.json` is ignored.

## Why triage stops

If tool discovery shows only `Cursor Automation Tools` and `cursor-cloud`, the Atlassian MCP server is not connected to the run. The agent cannot triage Jira until this is fixed in the Cursor dashboard.

## Fix (owner / team admin)

Automation: [SD Jira Triage](https://cursor.com/automations/801a2155-817e-11f1-a7d1-d6b4613131ce)

### 1. Register Atlassian as a Team MCP (HTTP)

1. Open [Dashboard → Integrations & MCP](https://cursor.com/dashboard/integrations)
2. Under **Team MCP Servers**, add a remote **HTTP** server
3. Use:

```json
{
  "mcpServers": {
    "Atlassian-MCP-Server": {
      "url": "https://mcp.atlassian.com/v1/mcp/authv2"
    }
  }
}
```

4. Do **not** use `mcp-remote`, SSE, or `https://mcp.atlassian.com/v1/sse` for Cloud Agents

### 2. Authenticate for the identity the automation runs as

OAuth is per-user (and for **Team Owned** automations, credentials must work for the **team automations service account**, not only a personal desktop login).

1. Open [cursor.com/agents](https://cursor.com/agents)
2. Open the MCP dropdown
3. Enable Atlassian and complete OAuth (or API token if your Atlassian admin enabled that)

### 3. Enable MCP on the automation

1. Open [SD Jira Triage](https://cursor.com/automations/801a2155-817e-11f1-a7d1-d6b4613131ce)
2. Under tools, enable **MCP server** and select the Atlassian server
3. Save

### 4. Verify

Re-run the automation (or wait for the next cron). Tool discovery should list Atlassian/Jira tools such as issue search, edit, and transition helpers. Then the skill can process `project = SD AND status = "Triage"`.

## Related docs

- [Cursor MCP](https://cursor.com/docs/mcp.md)
- [Cloud Agent MCP tools](https://cursor.com/docs/cloud-agent/capabilities.md#mcp-tools)
- [Automations — MCP server tool](https://cursor.com/docs/cloud-agent/automations.md)
- [Atlassian Rovo MCP IDE setup](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/setting-up-ides/)
