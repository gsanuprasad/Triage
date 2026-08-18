Run the jira-triage skill now.

Follow `.cursor/skills/jira-triage/SKILL.md` exactly, including its reference files under `.cursor/skills/jira-triage/references/`.

Process all SD project issues currently in "Triage" status.
If none are found, report "No issues currently in Triage." and stop.

Rules for this automation run:
- Use the Atlassian MCP for all Jira reads and writes.
- Leave issues unassigned after triage.
- Do not open pull requests.
- Do not modify repository code.
- Do not invent field values — only set fields when the skill rules say to.
- Process issues sequentially in this single run. Do not launch subagents, parallel cloud agents, or the Task tool — extra agents hit Cursor's concurrent-run cap and rate-limit later ticks.
