# Priority Matrix

Use this table to determine issue priority based on issue category and scope of impact.

**Scope definitions:**
- **All** — affects all users / system-wide / no scope limitation mentioned for a critical issue
- **Some** — affects multiple users or a team
- **One** — affects a single named user

| Issue Category | All | Some | One |
|---|---|---|---|
| Unable to login / System down | (0) Critical | (0) Critical | (2) High |
| Severe performance | (0) Critical | (1) Critical | (2) High |
| End of Month/Year rollover | (1) Critical | (1) Critical | (2) High |
| Creating Contract / Quote / Job / etc. | (1) Critical | (1) Critical | (3) High |
| Completing Rental Billing | (1) Critical | (1) Critical | (3) High |
| Mobility — SM, BMA, CRM | (1) Critical | (2) High | (4) High |
| Progressing Contract / Rental Quote / Multi-Line Docket / Invoice / Payment / PO / Job / Sales Order / Sales Quote | (1) Critical | (2) High | (5) Normal |
| Producing Contract / Invoice reports (print, email, etc.) | (1) Critical | (2) High | (5) Normal |
| Asset Processing: Activation/Disposal, Asset Finance | (1) Critical | (3) High | (5) Normal |
| Project Costing | (1) Critical | (3) High | (5) Normal |
| Billing / Invoicing Query | (1) Critical | (3) High | (5) Normal |
| End of Month reporting | (1) Critical | (3) High | (5) Normal |
| Mismatch/Imbalance in GL / Cashbook / Financial Contribution | (1) Critical | (3) High | (5) Normal |
| Producing Operational reports — PO / Creditor Invoice etc. | (1) Critical | (3) High | (5) Normal |
| Updating Debtor / Creditor / Site / Stock / Fleet / BOM etc. | (1) Critical | (3) High | (6) Normal |
| Creditor Invoice / Payment | (1) Critical | (3) High | (6) Normal |
| Security | (1) Critical | (4) High | (6) Normal |
| Password reset | (2) High | (2) High | (2) High |
| Reminder Service / Workflow / Gateway | (1) Critical | (4) High | (5) Normal |
| Producing Auditing / Functional reports | (2) High | (4) High | (6) Normal |
| Mismatch/Imbalance in Asset, Fleet or Stock Quantity | (2) High | (4) High | (6) Normal |
| Creating/Updating CRM | (3) High | (5) Normal | (6) Normal |
| Email | (3) High | (5) Normal | (7) Normal |
| Creating New User for Hosted Environment | (4) High | (4) High | (4) High |
| Modifications / Professional Services / Deployment | (5) Normal | (5) Normal | (5) Normal |
| Functionality Question / Documentation Request | (7) Normal | (7) Normal | (7) Normal |
| Spelling / Grammar — affecting users only | (9) Normal | (9) Normal | (9) Normal |

## Priority ID Mapping

When calling `editJiraIssue`, use the priority **name** exactly as shown (e.g. `(5) Normal`, `(0) Critical`). Jira will match by name.
