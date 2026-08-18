---
name: jira-triage
description: Automatically triage incoming Jira issues in the SD project (Baseplan Service Desk) that are in "Triage" status. Use this skill whenever the user says "run triage", "triage new tickets", "process the triage queue", "triage SD issues", or asks to process/review/clean up incoming support tickets. Also triggers automatically on schedule (daytime 8 AM–6 PM and overnight 10 PM–7 AM Sydney, every 30 minutes). Always remove blocked Baseplan support mailboxes from Request Participants and verify they are gone before finishing each issue.
---

# Jira Triage — Baseplan Service Desk (SD)

This skill processes all issues in the SD project that are in **"Triage"** status and performs the standard triage steps automatically. Issues are left **unassigned** after triage.

## Concurrency (scheduled cloud runs)

Process the queue **sequentially in this one run**. Do not launch subagents, parallel cloud agents, or the Task tool. Extra agents count toward Cursor's concurrent cloud-agent cap and cause later cron ticks to fail with "Rate limited / too many concurrent runs". Recovery steps: `infra/RATE-LIMIT.md`.

## Mandatory completion (every issue)

An issue is **not** finished until all of the following are done:

1. Field updates applied (step 2g), including Request Participants cleanup when needed
2. Transition attempted (step 2h)
3. Request Participants **verified clean** (step 2i) — re-read the field and confirm blocked support mailboxes are gone

Do not move to the next issue, and do not end the run, while any blocked support mailbox remains on Request Participants for an issue you processed.

**Blocked Request Participant emails** (case-insensitive; match `emailAddress` or `displayName`):

* `helpdesk@baseplan.com`
* `baseplanservicedesk@baseplan.com`
* `baseplanservicedesk@baseplanonline.com`
* `support@baseplan.com`

## Jira Connection Details

- **Cloud ID**: `47ce615b-398d-4e09-99f5-d0c64b17b2a5`
- **Project**: `SD`
- **Target status**: `Triage` (status ID: 10900)

## Step 1 — Fetch all issues in Triage

Run this JQL to get the queue:

```
project = SD AND status = "Triage" ORDER BY created ASC
```

Request these fields: `summary`, `description`, `issuetype`, `priority`, `assignee`, `reporter`, `comment`, `customfield_11800`, `customfield_10201`, `customfield_22407`, `customfield_22416`, `customfield_21636`, `customfield_22456`, `customfield_22576`, `customfield_22623`, `versions`, `*all`

If there are no results, report "No issues currently in Triage." and stop.

## Step 2 — Process each issue

For each issue, work through these steps in order. Collect all field changes **including Request Participants cleanup**, apply them in a single `editJiraIssue` call (step 2g), then transition (step 2h), then **mandatory verify** Request Participants (step 2i).

### 2a. Clean the Summary

Clean up the summary without changing the customer's meaning, wording, or intent.

**Allowed changes:**
- Remove leading email noise prefixes: `FW:`, `FWD:`, `RE:`, `URGENT`, `[EXTERNAL]` and variations (case-insensitive)
- Fix formatting and spacing
- Remove unnecessary blank lines
- Correct inconsistent capitalisation (e.g. ALL CAPS or random capital letters)
- Correct obvious spelling mistakes and simple grammar errors
- Standardise punctuation

**Do NOT:**
- Rewrite or rephrase the customer's words
- Change the meaning or intent
- Add information that was not provided
- Summarise or shorten the issue

Preserve product names, version numbers, field names, error messages, and technical terms exactly as written. If no formatting improvements are required, leave the summary unchanged.

**Examples:**
- `"FW: RE: URGENT - Cannot login"` → `"Cannot Login"`
- `"RENTAL BILLING ERROR ON SCREEN"` → `"Rental Billing Error On Screen"`

### 2b. Extract Customer Reference Number

Scan the original summary and description for patterns like:
- `#12345`, `REF-123`, `CAS-`, `INC-`, ticket numbers preceded by `##`, `*`, `//`

If found, note the value — you'll write it to the `Cust Ref Number` custom field. To find the correct custom field ID, call `getJiraIssueTypeMetaWithFields` for the issue's type and look for a field with name containing "Cust Ref" or "Customer Ref". If you can't find the field, include the ref in the triage comment instead.

### 2c. Classify Issue Type

Default is `Support`. Change it based on these signals from summary + description:

| Keyword / Signal | Issue Type |
|---|---|
| modification, enhancement, new feature, change request | Modification |
| training, how to use, learn, workshop | Training |
| implementation, go-live, setup, onboarding | PS Support |
| deploy, deployment, hotfix, release, install | Deployment |
| data conversion, data migration, import, export data | Data Conversion |
| configuration, parameter, setup config | Configuration |
| custom report, crystal report, SSRS | Custom Report |
| project management, project phase | Project Management |
| Baseplan staff creating internal task (no external customer) | keep as-is |

Use AI judgment for ambiguous cases — look at the full description, not just keywords.

**Application Support Issue Type rule (applies to every task):** When Tempo Team is **Application Support** (`ps_matched` is false — see 2c.2 / 2g), the Issue Type written in step 2g **must remain `Support`** (ID: `10900`).

- Do not change the Issue Type to **Consulting** or any other value for Application Support tasks.
- Do not apply the keyword / signal Issue Type changes from the table above to the Issue Type field when Tempo Team is Application Support.
- Do not modify the Issue Type for Application Support tasks under any other circumstances.

The only exception is the Professional Services project classification rule in step 2c.2, which may set Issue Type to `Consulting` together with Tempo Team **Professional Services** — but only when the reporter is an external customer (not a Baseplan staff member).

### 2c.2. Check PS Project Classification

Read `references/ps-projects.md`.

**Matching:**
1. Get the Jira org name from `customfield_11800[0].name` (e.g. `"ACROW"`, `"FIELDFORCE"`)
2. Normalize it: convert to lowercase, strip leading/trailing whitespace
3. Compare against each Customer name in the reference table, also normalized (lowercase, stripped)
4. Exact match only — no partial matching, no guessing, no inferring

**Baseplan reporter check (apply before PS routing):**

The **Reporter** field is the main contact. Before routing a PS project match to Professional Services, inspect `reporter`:

| Reporter signal | Is Baseplan staff? |
|---|---|
| `reporter.emailAddress` ends with `@baseplan.com` (case-insensitive) | Yes |
| Email unavailable and `reporter.accountType` is `atlassian` | Yes |
| Otherwise | No — treat as external customer contact |

If the organisation matches `ps-projects.md` **and** the reporter is a Baseplan staff member, **do not** apply PS classification. Leave `ps_matched = false`, keep the issue type from step 2c (typically `Support`), and route to Application Support in step 2g. Note in AI Triage Summary: `PS project match (<customer>) skipped — reporter is a Baseplan staff member (<reporter display name or email>). Routed to Application Support.`

| Outcome | Action |
|---|---|
| **Exactly one match, reporter is external** | Override Issue Type → `Consulting` (ID: `11104`). Store the matched Job Code and set `ps_matched = true`. Tempo Team will be set to Professional Services in step 2g. This is the explicit exception to the Application Support → Support Issue Type rule. |
| **Exactly one match, reporter is Baseplan staff** | Do not apply PS classification. Leave `ps_matched = false`. Triage as normal Support; Tempo Team → Application Support in step 2g. |
| **No match** | No change from the Application Support rule — Issue Type remains `Support`. Continue with normal triage. Do not add anything to AI Triage Summary. |
| **Multiple matches** | Do not change Issue Type, Job Code, or Tempo Team. Issue Type remains `Support` for Application Support. Append to AI Triage Summary: `"Project classification was not applied because multiple matching Customer Codes were found in the reference sheet. Please review and assign the correct project manually."` |

**When `ps_matched = true`, also look up the Job Code field key:**
Call `getJiraIssueTypeMetaWithFields` for issue type `Consulting` (ID `11104`) and search the returned field list for a field whose name contains "Job Code" or "Job Number". Note the field key (e.g. `customfield_XXXXX`) — you will use it in step 2g to set the Job Code value from the reference.

If you cannot find the Job Code field, leave it blank and flag in the AI Triage Summary: `⚠️ PS match found (Job Code: <value>) but Job Code field key not identified — set manually.`

### 2c.5. Determine Module

Review all available information — summary, description, customer comments, internal comments, screenshots, error messages, screen names, menu names, report names, field names, SQL objects, and the workflow being performed — to determine which functional area of Baseplan is primarily affected.

Choose exactly one Module. Select the module where the issue **originates**, not necessarily where the error becomes visible. If multiple modules are involved, choose the one where investigation would most likely begin. Only select **All** when the issue genuinely spans multiple modules with no clear owner.

| Module | Covers |
|---|---|
| Rental | Rental Contracts, Quotations, Reservations, Dispatch, Pickups, Returns, Off Hire, Rental Rates, Rental Billing, Extensions, Availability, Rental Invoicing |
| Equipment | Equipment Master, Plant records, Fleet, Serial Numbers, Meters, Inspections, Equipment Status, Availability, Movements |
| Assets | Fixed Assets, Asset Register, Depreciation, Asset Disposal, Capital Assets |
| Customers | Customer records, Contacts, Pricing, Credit Limits, Statements, Customer Master |
| Suppliers | Supplier Master, Supplier Accounts, Supplier Configuration |
| Purchase Orders | Purchase Requisitions, Purchase Orders, Goods Receipts, AP Automation, Supplier Invoice Processing, Purchase Approvals |
| Stock | Inventory Items, Warehouses, Stock Transfers, Stock Adjustments, Parts, Inventory Transactions |
| Service | Workshop, Maintenance Jobs, Work Orders, Equipment Servicing, Repairs, Service Scheduling, Service History |
| Sales | Sales Quotes, Sales Orders, Sales Invoices, Counter Sales, Non-Rental Sales |
| General Ledger | General Ledger, Journals, Financial Posting, Tax, GST/VAT, Chart of Accounts, Financial Periods, Bank Reconciliation |
| CRM | Leads, Opportunities, Activities, Campaigns, Pipeline, CRM Contacts |
| Reports | Crystal Reports, BI Reports, Dashboards, Report Output, Report Formatting, Missing Report Data |
| Security | Login, Authentication, User Accounts, Passwords, Roles, Permissions, MFA, Portal Access |
| Utilities | Imports, Exports, Background Jobs, Integrations, Data Conversion, System Utilities, Batch Processing |
| Financials | Financial reporting, financial configuration, financial workflows not covered by General Ledger |
| Inspections | Equipment inspections, inspection checklists, inspection workflows, service on return inspections |
| Payroll | Payroll processing, pay runs, employee pay, payroll configuration |
| Projects | Project management, project costing, project phases, project tracking |
| Transport | Transport management, delivery scheduling, docket management, logistics |
| All | Genuinely affects multiple modules equally; no single clear owner |

**Field:** `customfield_22410` (multiselect — always pass as a single-element array)

| Module | Option ID |
|---|---|
| All | 14124 |
| Assets | 14125 |
| CRM | 14126 |
| Customers | 14127 |
| Equipment | 14128 |
| General Ledger | 14130 |
| Purchase Orders | 14134 |
| Rental | 14135 |
| Reports | 14136 |
| Sales | 14137 |
| Security | 14138 |
| Service | 14139 |
| Stock | 14140 |
| Suppliers | 14141 |
| Transport | 14142 |
| Utilities | 14143 |
| Financials | 14129 |
| Inspections | 14131 |
| Payroll | 14132 |
| Projects | 14133 |

### 2d. Set Priority

Read `references/priority-matrix.md` to determine the correct priority.

To use the matrix:
1. **Identify the issue category** — match the summary/description to a row in the matrix (e.g. "Unable to login", "Billing Query", "Modification")
2. **Determine scope** from the description:
   - **All** — system-wide, all users affected, or no scope mentioned for a critical system issue
   - **Some** — multiple users or a team affected
   - **One** — a single named user affected
3. Look up the intersection cell and set that priority

If the category is unclear, default to `(5) Normal` and note the uncertainty in the triage comment.

### 2e. Clean the Description

Clean up the description without changing the customer's meaning, wording, or intent.

**Allowed changes:**
- Remove email salutations (Hi X, Dear X, Hello, etc.) and sign-offs (Thanks, Regards, Kind regards, etc.)
- Remove signature blocks (company name, phone number, address lines)
- Fix formatting and spacing
- Remove unnecessary blank lines
- Correct inconsistent capitalisation (e.g. ALL CAPS or random capital letters)
- Correct obvious spelling mistakes and simple grammar errors
- Standardise punctuation
- Format lists, bullet points, and code blocks for readability
- If an error message is present but not clearly labelled, prepend it with `Message: `

**Do NOT:**
- Rewrite or rephrase the customer's sentences
- Change the meaning or intent
- Add information that was not provided
- Remove details because they appear repetitive
- Summarise the customer's issue
- Interpret or infer what the customer meant
- Change quoted text or exact error messages
- Modify SQL, code snippets, log output, stack traces, file names, or configuration values

Preserve product names, version numbers, field names, error messages, and technical terms exactly as written. If no formatting improvements are required, leave the description unchanged.

### 2e.5. Detect Environment

Review the issue summary, description, comments, and any readable attachment text. Apply these rules in order:

1. If any of the following are explicitly mentioned, set the environment accordingly:
   - **UAT** or "User Acceptance Testing" → `UAT` (`{"id": "14164"}`)
   - **TEST**, "Testing environment", "Only reproducible in TEST", "test database" → `Test` (`{"id": "14165"}`)
   - **Training**, "training database", "training environment" → `Training` (`{"id": "14163"}`)
   - **Development**, **DEV**, "dev environment", "development server" → `Development` (`{"id": "14166"}`)

2. If multiple environments are mentioned, select the one where the issue is **currently occurring** or where assistance is being requested. If unclear, use the most specifically stated environment.

3. If **no environment is explicitly mentioned**, default to **Production** (`{"id": "14162"}`).

**Important:** Do not infer UAT/TEST simply because the issue relates to an upgrade, a patch, or testing activity — only set non-Production if the environment is explicitly stated.

Compare the detected value against the current `customfield_22456` value on the issue. Only include `customfield_22456` in the `editJiraIssue` call (step 2g) if the value needs to change.

| Environment | Field value |
|---|---|
| Production | `{"id": "14162"}` |
| Training | `{"id": "14163"}` |
| UAT | `{"id": "14164"}` |
| Test | `{"id": "14165"}` |
| Development | `{"id": "14166"}` |

### 2f. Look up Organisation, Affected Version, Customer SLA + Maintenance Branch

Run a single lookup to find the most recent **already-triaged** issue for the same organisation (i.e. not in Triage status). This result is used to populate Affected Version, Customer SLA, and Maintenance Branch.

**If `customfield_11800` is populated** (org is set on the issue):

Get the org ID from `customfield_11800[0].id` and run:

```
project = SD AND "Organizations" = <org_id> AND status != "Triage" AND issue != <current_key> ORDER BY updated DESC
```

**If `customfield_11800` is empty** (no org set):

Fall back to the reporter's `accountId` and run:

```
project = SD AND reporter = <reporter_accountId> AND "Organizations" is not EMPTY AND status != "Triage" AND issue != <current_key> ORDER BY updated DESC
```

For the reporter fallback, also copy `customfield_11800` from the result (set as a numeric array e.g. `[18620]`).

**For both cases**, fetch fields: `customfield_11800`, `customfield_22416`, `versions`, `customfield_22576` from the first result.

Then apply the following rules for each field — only set a field if the **current issue's field is empty** or **different** from the value found:

| Field | Custom field | Copy if previous has a value? |
|---|---|---|
| Customer SLA | `customfield_22416` | Yes — e.g. `{"id": "14152"}` |
| Affected Version | `versions` | Yes — e.g. `[{"id": "23695"}]` |
| Maintenance Branch | `customfield_22576` | Yes — e.g. `{"id": "14427"}` (Yes) or `{"id": "14428"}` (No) |

**Rules when using values from previous tasks:**
- Do **not** guess or infer values — only copy if the field is explicitly set on the previous task and the value matches an available Jira field option.
- Do **not** copy values from a different customer or organisation.
- Do **not** use tasks with status Cancelled, Duplicate, Rejected, or Closed as "Won't Fix" as the source.
- If multiple previous tasks are found, use the most recent one that has the relevant fields populated.
- If the current task already has correct values set, do not overwrite them.
- If no suitable previous task is found, or the previous task does not have a field populated, leave that field unchanged and flag it in the AI Triage Summary (e.g. `⚠️ No previous task found for Maintenance Branch — left blank`).

If multiple results are returned, scan through them (up to 5) until one is found that meets the above criteria. If none qualify, leave the fields unchanged and flag.

### 2f.5 Search for Relevant Historical Tasks

**Skip this step entirely for User Management requests** — i.e. any issue whose summary or description contains signals like "new user", "user setup", "set up user", "create user", "user access", "BMA access", "Enterprise user", or similar. For these, set `related_issues = []` and move on.

For all other issues, search all Jira tasks to find historical tasks genuinely relevant to the current issue.

**Extract search terms from all available content:**
- Task summary and description
- Customer comments and internal notes
- Error messages and stack traces
- Screen names, report names, API names
- Process or workflow names
- Specific symptoms and business impact language

Prefer specific technical terms (e.g. exact error text, module/screen/field names, entity names). Avoid generic words like "error", "user", "issue". Run multiple targeted searches if needed to cover different angles (e.g. one for the error message, one for the screen name).

```
project = SD AND text ~ "<specific terms>" AND issue != <current_key> ORDER BY updated DESC
```

**Filtering rules — exclude:**
- Duplicate, Cancelled, or Rejected tasks
- Tasks with only weak single-word keyword overlap — the overall issue, symptoms, error, process, or behaviour must closely match

**For each relevant result, evaluate similarity:**
- **High** — same error, same screen/module, same root cause or symptoms
- **Medium** — related process or workflow, similar symptoms but different context

Only return tasks with High or Medium similarity. Do not list weak matches.

Store results as `related_issues` (max 5). If no relevant task is found, set `related_issues = []`.

**Format for AI Triage Summary** (one entry per line):
`SD-XXXXX (<status>) — <summary> [High/Medium]`

If no relevant task is found, omit the Related section entirely (do not write "No relevant task found" in the summary field).

### 2g. Apply Field Updates

**Before calling `editJiraIssue`**, build the Request Participants cleanup from the current `customfield_10201` value:

1. Start from the current participants list (may be empty).
2. Drop any participant whose `emailAddress` or `displayName` matches a **Blocked Request Participant email** (see top of skill).
3. Keep every other participant unchanged.
4. If any blocked address was removed, include `customfield_10201` in this edit as an array of `{"accountId": "<id>"}` for the remaining participants (`[]` if none remain).
5. If no blocked address was present, omit `customfield_10201` from this edit.

Call `editJiraIssue` with all collected changes **in this same call** (do not defer Request Participants cleanup to later):
- `summary` — cleaned value from 2a
- `issuetype` — use the issue type ID, not name:
  - If `ps_matched = true`: `Consulting` (ID: `11104`) from step 2c.2 (Professional Services Tempo Team)
  - If Tempo Team is **Application Support** (`ps_matched` is false): always `Support` (ID: `10900`). Do not set Consulting or any other Issue Type.
- `priority` — from 2d (use priority name exactly, e.g. `(5) Normal`, `(2) High`, `(0) Critical`)
- `description` — cleaned value from 2e
- `assignee` — do **not** set; leave unassigned
- `customfield_22407` — Cust Ref Number, if found in 2b
- `customfield_21636` — Tempo Team:
  - If `ps_matched = true`: `{"id": 7}` (Professional Services)
  - Otherwise: `{"id": 19}` (Application Support)
- `customfield_XXXXX` — Job Code: if `ps_matched = true`, set to the numeric Job Code value from `references/ps-projects.md` using the field key found in step 2c.2. Omit if no match or field key not found.
- `customfield_22456` — Environment, detected in step 2e.5 (only include if value differs from current)
- `customfield_11800` — Organisation, if inherited from reporter fallback in 2f (numeric array, e.g. `[18620]`)
- `customfield_22416` — Customer SLA inherited from 2f, e.g. `{"id": "14152"}`
- `versions` — Affected Version inherited from 2f, e.g. `[{"id": "23695"}]`
- `customfield_22576` — Maintenance Branch inherited from 2f, e.g. `{"id": "14427"}` (Yes) or `{"id": "14428"}` (No) — only if found
- `customfield_22410` — Module, determined in step 2c.5 (single-element array, e.g. `[{"id": "14135"}]`)
- `customfield_10201` — Request Participants cleaned as above (**required in this call when any blocked mailbox was present**)
- `customfield_22623` — AI Triage Summary (see format below)


**AI Triage Summary format** — written to `customfield_22623` as **Atlassian Document Format (ADF)**. The field does not accept plain text strings. Use this ADF structure, with one paragraph per logical section (classification/priority summary, related issues if any, and any flags/warnings):

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "Type: <issue type classification and brief reasoning>. Module: <module>. Priority: <priority> (<matrix category>, scope: <All/Some/One>). Environment: <environment>. <note any fields inherited from a prior ticket and which ticket>."
        }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "Related: SD-XXXXX (<status>) — <summary> [High/Medium]"
        }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "⚠️ <any flags — e.g. field not found, multiple PS matches, issue type could not be changed, etc.>"
        }
      ]
    }
  ]
}
```

Omit the "Related" paragraph entirely if `related_issues` is empty (per 2f.5). Omit the flags paragraph if there are no flags.

### 2h. Transition the Issue

Once all field updates in 2g have been applied, move the issue out of Triage.

1. Call `getTransitionsForJiraIssue` for the issue to get the current, live list of available transitions — do not hardcode a transition ID, as these can vary by workflow/project configuration.
2. Look for the transition named "Triaged". In the current SD workflow this moves the issue from `Triage` to `1st Response`.
3. Call `transitionJiraIssue` with that transition's `id`.
4. If no transition named "Triaged" is available on the issue (e.g. a custom workflow variant), do not guess at an alternative. Leave the issue in Triage status, note the discrepancy in the AI Triage Summary, and flag it for manual review.

Do not set an assignee as part of this transition — issues are left unassigned per the top-level instruction.

### 2i. Verify Request Participants Cleanup (mandatory)

This step is **mandatory for every issue**, even if step 2g already cleaned Request Participants, and even if the Triaged transition failed and the issue is still in Triage.

1. Re-fetch the issue fields including `customfield_10201` (do not rely on memory of the earlier value).
2. Check whether any participant still matches a **Blocked Request Participant email** (case-insensitive on `emailAddress` or `displayName`).
3. If any blocked address is still present:
   - Call `editJiraIssue` and set `customfield_10201` to the filtered remaining participants as `[{"accountId": "<id>"}, ...]` (`[]` if none remain).
   - Re-fetch `customfield_10201` again.
   - If a blocked address is **still** present after the retry, flag it in the run report for that issue key and note `⚠️ Request Participants cleanup failed — blocked support mailbox still present` (update AI Triage Summary if still editable).
4. If no blocked address is present, continue to the next issue.
5. **Do not** mark the issue complete, move to the next issue, or end the automation run while a blocked support mailbox remains on an issue you processed — unless the retry already failed and was flagged.

Only remove the blocked support mailboxes listed at the top of this skill. Leave all other request participants unchanged.
