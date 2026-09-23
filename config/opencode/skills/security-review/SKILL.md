---
name: asvs-review
description: conduct a static code review according to ASVS 5.0
license: MIT
---

# ASVS 5.0 Static Code Review

You are conducting a structured static code analysis guided by the OWASP Application Security Verification Standard (ASVS) 5.0. Follow the steps below precisely and interactively.

---

## Operating principles

These apply throughout the entire session:

- **Never work around a restriction.** If anything is blocked — network access to a reference URL, a file you cannot read, a missing permission — stop and surface it to the reviewer with a clear, specific explanation and explicit choices. Do not silently skip it, and do not invent a bypass: no alternative mirrors, no cache/proxy services, no search-engine result pages, no `web.archive.org` in place of the real source, and never disable TLS/certificate verification. A blocked resource is a decision for the reviewer to make, not a problem for you to route around.
- **This review is resumable.** Reviews often run in a sandbox with limited outbound HTTP access. The reviewer can allow specific network hosts, but only from outside this Claude Code session, and the change may take effect only after the sandbox is restarted. When a restart is needed, you save a checkpoint so a fresh session can continue from exactly where it stopped (see Step 0 and Step 5).

---

## Output economy

Keep generated output lean — it is billed and it slows the run. This never means dropping findings or evidence; it means not spending words on things that carry no information:

- **Don't repeat instructions or inputs.** Never echo this command's steps, the config values, or the ASVS criterion text back to the reviewer. Refer to criteria by ID (e.g. `6.1.2`), not by pasting their wording.
- **Don't narrate.** Skip step-by-step commentary ("Now loading references…", "Analysing 6.1.1…"). Work silently; speak only to ask for a decision or to deliver results.
- **Spend words where they matter, but always justify the verdict.** FAIL and NEEDS MANUAL REVIEW get full evidence and rationale. PASS and NOT APPLICABLE stay short — ID, verdict, a `file:line` reference, and a brief rationale (one sentence) explaining _why_ the requirement is considered met or not applicable, so the reviewer can check the assumption behind it. Where the code implements a control well, it is fine to say so plainly. Keep it to the reasoning — drop filler, not substance.
- **Reference, don't quote code.** Cite `path:line`. Include a code snippet only when the snippet itself is the evidence for a FAIL, and then only the few relevant lines.
- **Write once.** When `write_report` is true the report file is the deliverable — do not also reprint its full contents in the session (see Step 7).
- **No filler.** Skip preambles, restated summaries, and closing pleasantries. One summary line at the end is enough.

---

## Step 0 — Resume an interrupted review

Before anything else, check for a checkpoint file at `./asvs-reports/.asvs-resume.json` in the project being reviewed.

If it does **not** exist, proceed to Step 1 as a normal run.

If it **exists**, a previous review was interrupted — typically to restart the sandbox for a network allow-list change. Read it and confirm with the reviewer via `AskUserQuestion` (single select):

- Header: `Resume`
- Question: "I found an interrupted ASVS review from {created}, stopped while loading references for chapter V{current_chapter}. Resume where it left off?"
- Options:
  - `Resume` — continue from the saved point
  - `Start fresh` — discard the checkpoint and begin a new review

If `Start fresh`: delete the checkpoint file and the `./asvs-reports/.resume/` directory, then go to Step 1.

If `Resume`:

- Restore the saved session parameters from `resolved_config`, `execution_mode`, and `chapters`. Do **not** re-run the config interview (Steps 1–4).
- Treat every chapter in `progress.completed_chapters` as done. Their finished output is preserved — in report files if `write_report` is true, otherwise under `./asvs-reports/.resume/`. Do not re-analyse them; read their output back so it can be consolidated into the final output.
- Go to **Step 5** for `progress.current_chapter`, retrying `progress.pending_urls` **first** (the reviewer allowed those hosts before restarting). Then continue with Step 6 and any remaining chapters as normal.

### Checkpoint file format

`./asvs-reports/.asvs-resume.json`:

```json
{
  "version": 1,
  "created": "2026-07-17T1430",
  "reason": "awaiting-sandbox-restart-for-network-unblock",
  "resolved_config": {
    "asvs_doc_path": "~/.config/opencode/resources/asvs-5",
    "language": "de",
    "level": 2,
    "output_format": "table",
    "write_report": true,
    "echo_report_to_session": false,
    "excluded_criteria": ["1.1.2"],
    "session_exclusions": ["6.2.3"],
    "projectStructure": [],
    "context_notes": "..."
  },
  "execution_mode": "sequential",
  "chapters": [6, 7, 8],
  "progress": {
    "completed_chapters": [6],
    "current_chapter": 7,
    "phase": "loading-references",
    "pending_urls": [
      "https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html"
    ],
    "blocked_hosts": ["cheatsheetseries.owasp.org"]
  }
}
```

The timestamp in `created` comes from `date +"%Y-%m-%dT%H%M"` via Bash — never guess it.

---

## Step 1 — Load project config

Look for `.claude/asvs-config.json` in the **current working directory** (i.e., the project being reviewed, not the ASVS workspace). Parse it if it exists. Track which fields are present and which are missing.

Expected fields:

- `asvs_doc_path` — path to the ASVS 5.0 markdown files (the `asvs-5/` directory)
- `chapters` — array of chapter numbers relevant for this project (e.g., `[1, 6, 8]`)
- `level` — ASVS assurance level to audit against (1, 2, or 3)
- `excluded_criteria` — array of criterion IDs to always skip (e.g., `["1.1.2", "6.2.3"]`)
- `language` — language for all output and the report: `"en"` or `"de"` (default: `"en"`)
- `output_format` — `"table"`, `"checklist"`, or `"findings-only"` (default: `"table"`)
- `write_report` — whether to write findings to a markdown report file in addition to displaying them (`true` / `false`, default: `false`)
- `echo_report_to_session` — when `write_report` is true, also print the full report in the session instead of just a compact recap. Costs more output tokens (findings are emitted twice). (`true` / `false`, default: `false`)
- `context_notes` — free-text application context
- `projectStructure` — array of objects describing the project layout, each with:
  - `folder` — relative path to the component (e.g., `"./backend"`)
  - `contents` — short description of what the component is
  - `languagesAndFrameworks` — array of languages/frameworks used (e.g., `["C#", "ASP.NET MVC"]`)

If the file does not exist, all fields are treated as missing.

---

## Step 1b — Scan existing reports

Look for report files in `./asvs-reports/`. If the directory does not exist or is empty, treat all configured chapters as unreviewed.

For each `.md` file found, extract the chapter identifier from the filename (pattern: `V{N}-…`). Build a map of:

- **Reviewed chapters** — chapter numbers for which at least one report exists, along with the most recent report's timestamp (from the filename)
- **Unreviewed chapters** — configured chapters with no corresponding report file

Use this map throughout the session:

- In **Step 3**, show reviewed chapters with a `✓ last reviewed {date}` annotation in the selection list, so the user can see at a glance what is already covered
- In the **Closing**, when suggesting what to do next, prioritise unreviewed chapters over already-reviewed ones

---

## Step 2 — Resolve missing config fields interactively

Ask only for fields that are missing from the config. Use the `AskUserQuestion` tool for all structured questions — this renders a proper multiple-choice UI. Collect all missing fields before offering to save.

**If `language` is missing** — use `AskUserQuestion` (single select, ask this first):

- Header: `Language`
- Question: `In which language should the analysis and report be written?`
- Options:
  - `English`
  - `German (Deutsch)`

Store as `"en"` or `"de"` in the config. Use this language for all output — findings, verdicts, rationale, remediation hints, and the report file — from this point on.

**If `level` is missing** — use `AskUserQuestion` (single select):

- Header: `ASVS Level`
- Question: `Which ASVS assurance level should I audit against?`
- Options:
  - `Level 1` — Basic security. Most critical, widely applicable requirements. Good starting point.
  - `Level 2` — Standard. Recommended for most applications handling sensitive data.
  - `Level 3` — Advanced. For high-value applications requiring strong security assurance.

**If `output_format` is missing** — use `AskUserQuestion` (single select):

- Header: `Output format`
- Question: `In which format should I present the findings?`
- Options:
  - `Table` — Markdown table with ID, verdict, and evidence per criterion
  - `Checklist` — GitHub-style checkboxes grouped by section
  - `Findings only` — Only failures and items needing manual review, with remediation hints

**If `write_report` is missing** — use `AskUserQuestion` (single select):

- Header: `Write report`
- Question: `Should I also write the findings to a report file under ./asvs-reports/?`
- Options:
  - `Yes` — Write a markdown report file in addition to showing results in the session
  - `No` — Show results in the session only

  Do **not** prompt for `echo_report_to_session`. It is an advanced, config-only option (enabling it duplicates output and increases token usage); treat it as `false` unless it is explicitly set in the config file.

**If `chapters` is missing** — use `AskUserQuestion` (multi-select, `multiSelect: true`):

- Header: `Chapters`
- Question: `Which ASVS chapters are relevant for this project?`
- Options:
  - `V1–V5` — Encoding, Validation, Web Frontend, API, File Handling
  - `V6–V8` — Authentication, Session Management, Authorization
  - `V9–V11` — Tokens, OAuth/OIDC, Cryptography
  - `V12–V17` — Communication, Configuration, Data Protection, Secure Coding, Logging, WebRTC

After the user selects one or more groups, confirm or refine the exact chapter numbers with a short follow-up text question if the user wants to exclude specific chapters within a group.

**If `projectStructure` is missing** — free-text (structured multi-part input):

> Please describe the structure of this project. For each component, provide:
>
> - The folder path (e.g. `./backend`)
> - A short description of its contents (e.g. `API service`)
> - The languages and frameworks used (e.g. `C#, ASP.NET MVC`)
>
> Add as many components as needed.

**If `context_notes` is missing** — free-text:

> Is there anything security-relevant about this application that is not visible in the code itself? For example:
>
> - Authentication or session management handled by an external system (e.g. external IdP, SSO)
> - API gateway or WAF that enforces certain controls upstream
> - Internal-only tool with no public exposure
> - Known compliance requirements or threat model specifics
>
> (Type `skip` if nothing applies.)

After collecting all missing values, use `AskUserQuestion` (single select):

- Header: `Save config`
- Question: `Save these settings to .claude/asvs-config.json for future runs?`
- Options:
  - `Yes` — Save all answers to the config file
  - `No` — Use for this session only

If yes, write or update the config file with the collected values, preserving any existing fields.

---

## Step 3 — Select chapter/section for this run

If the config (or user input) covers more than one chapter, use `AskUserQuestion` (single select):

- Header: `Chapter`
- Question: `Which chapter would you like to review in this session?`
- Options: one entry per configured chapter, annotated with review status from Step 1b (e.g. `V6 — Authentication  ✓ 2026-06-20` or `V8 — Authorization  (not yet reviewed)`), plus:
  - `All chapters — sequentially` — process each chapter one after the other in this session
  - `All chapters — in parallel` — spawn one sub-agent per chapter simultaneously (faster, results collected at the end)
  - `Unreviewed chapters only — in parallel` — same as above but skips chapters that already have a report

To review a specific section only (e.g. `6.2`), the user can add a note in the free-text "Other" option.

Store the user's choice as the **execution mode**: `single`, `sequential`, or `parallel`.

**On larger codebases, prefer a parallel (sub-agent) mode.** Beyond running faster, each sub-agent reads source files into its _own_ context window and returns only a compact findings block — so the heavy file reads never accumulate in the orchestrator's context. This is the single biggest input-token saving available here. Reserve `single` / `sequential` for small codebases or when you want to watch one chapter's analysis unfold interactively.

Resolve the target ASVS markdown file from `asvs_doc_path`. The filename pattern is:
`0x{hex}-V{N}-{Title}.md` where hex = N + 15 (decimal). For example, V6 → `0x15-V6-Authentication.md`.

---

## Step 4 — Interview phase

Ask the following before starting the analysis.

1. **Runtime exclusions** — use `AskUserQuestion` (single select):
   - Header: `Skip criteria`
   - Question: `Do you want to skip any ASVS criteria for this session only?`
   - Options:
     - `No` — proceed with all criteria (minus any already in `excluded_criteria`)
     - `Yes` — I'll specify IDs to skip

   If the user selects `Yes`, follow up with a free-text question: "Enter the criterion IDs to skip, comma-separated (e.g. `6.2.3, 6.4.1`)."

---

## Step 4b — Parallel execution (only if execution mode is `parallel`)

Skip this step if the execution mode is `single` or `sequential`.

**Prerequisite:** complete Step 5 (reference loading) yourself, as the orchestrator, for **all** selected chapters _before_ spawning any sub-agent. Sub-agents cannot prompt the reviewer, so all interactive network handling must be finished first. By the time you fan out, every reference is either cached on disk or was explicitly skipped by the reviewer.

Spawn one sub-agent per configured chapter using the `Agent` tool. Launch all agents in a single message so they run concurrently. Each agent is fully self-contained and receives the following prompt:

---

_Sub-agent prompt template (fill in the placeholders):_

> You are performing an ASVS 5.0 static code analysis for chapter **{chapterName}** (e.g. "V6 Authentication").
>
> Configuration:
>
> - ASVS docs: `{asvs_doc_path}`
> - Chapter file: `{chapterFile}` (e.g. `0x15-V6-Authentication.md`)
> - Assurance level: {level}
> - Excluded criteria: {excluded_criteria}
> - Language: {language}
> - Project structure: {projectStructure}
> - Context notes: {context_notes}
> - Working directory (project being reviewed): `{cwd}`
> - Reference cache directory: `{cachePath}`
>
> The orchestrator has already fetched and cached every reference for this chapter. Read reference summaries **only** from the cache directory above. **Never fetch from the network and never use a workaround** — if a reference file you need is missing from the cache, do not fetch it and do not substitute another source; note it as a limitation in the affected finding and continue. Perform Step 6 (analysis) from the asvs-review command exactly as described. Return your results as a structured markdown block:
>
> - Section heading: `## V{N} {Title}`
> - One sub-section per ASVS section within the chapter
> - All findings formatted for the `{output_format}` format
> - Include all evidence with `../`-prefixed file paths (report will live in `./asvs-reports/`)
> - At the end, include a summary line: `TOTAL: X evaluated / X pass / X fail / X n/a / X manual`
>
> Apply the output-economy rules: no preamble, do not restate this prompt or the criterion text, one-line rows for PASS / NOT APPLICABLE, full evidence and rationale only for FAIL and NEEDS MANUAL REVIEW. Return only the structured markdown block — nothing else.
>
> **Do NOT write any files.** Do not create a report file, do not write to `./asvs-reports/`, do not modify any config. Your only output is the markdown text returned to the calling agent.

---

Collect all sub-agent results. Then proceed directly to Step 7 (Output). Concatenate the sub-agents' returned blocks **verbatim** into the combined output — do not regenerate, re-summarise, or reformat them. Step 5 was handled centrally by you before fan-out; Step 6 was handled by the sub-agents.

---

## Step 5 — Load reference documents (orchestrator only)

Reference loading always runs in **this (the orchestrating) agent**, never in a sub-agent — because handling a blocked network host requires prompting the reviewer, and sub-agents cannot do that.

- In `single` and `sequential` mode: load references for the current chapter now, before its analysis.
- In `parallel` mode: load references for **all** selected chapters now, before spawning any sub-agents (Step 4b). The sub-agents will then read everything from the cache.

These documents contain best practices, attack patterns, and implementation guidelines that you must be familiar with in order to correctly judge code during analysis.

Collect all URLs from each relevant chapter's `## References` section.

Cache directory: `{asvs_doc_path}/../cache/` — i.e., next to the `asvs-5/` folder, typically `~/.config/opencode/resources/cache/` (create if it does not exist).

For each URL:

1. Derive a filename slug: replace `https://`, `://`, `/`, `.`, `?`, `=`, `#` with `-`, strip leading/trailing dashes, limit to 80 characters → `{slug}.md`
2. Check if `cache/{slug}.md` exists:
   - **Exists** → read it from disk. Do not fetch from the network.
   - **Does not exist** → fetch the URL, extract the security-relevant content, write the file, then read it:

```
---
source: {original URL}
fetched: {today's date}
---

# {Page title or URL}

{Concise summary of the security-relevant content: key definitions, requirements, recommendations, attack patterns, secure and insecure implementation examples. 150–300 words — only what is needed to judge code; no boilerplate.}
```

### If a fetch is blocked (restricted-network sandbox)

Reviews often run in a sandbox with restricted outbound HTTP. If a fetch fails with a network-level error (DNS failure, connection refused/timeout, TLS error) or an HTTP error indicating the host is unreachable or blocked, do **not** apply any workaround (see _Operating principles_) — no mirrors, no cache/proxy services, no disabling of TLS checks, and do not silently skip the reference and pretend it was consulted. Instead:

1. **Batch first.** Keep going through the remaining URLs so you can handle all blocked references together. Track the failed URLs and their distinct hosts.
2. **Explain plainly** to the reviewer: which reference documents could not be loaded, which host(s) would need to be allowed, and that these are guidance documents (OWASP / NIST / etc.) used to judge code accurately — without them the review can still proceed, but findings for the affected criteria may be less precise.
3. **Ask** via `AskUserQuestion` (single select):
   - Header: `Network`
   - Question: "{N} reference document(s) could not be loaded because these host(s) appear to be blocked: {hosts}. You can allow them from outside this session. How should I proceed?"
   - Options:
     - `Allowed it — retry` — I have added the host(s) to the network allow-list; retry the fetch now.
     - `Continue without` — proceed without these references; affected findings will note the missing source.
4. On `Allowed it — retry`: attempt the still-failing URLs again.
   - **All succeed** → continue normally.
   - **Still failing** → ask **again** via `AskUserQuestion` (single select), this time including the restart hint:
     - Header: `Network`
     - Question: "The fetch still fails for {hosts}. Network allow-list changes often take effect only after the sandbox is restarted. How do you want to proceed?"
     - Options:
       - `Restart sandbox` — save a checkpoint now; I'll restart the sandbox, then re-run the command to resume here.
       - `Retry again` — I changed something else; try once more without restarting.
       - `Continue without` — proceed without these references.
     - On `Restart sandbox`:
       1. **Persist all work so far** so the restart loses nothing. Completed chapters already written to report files are safe; write any completed-but-unwritten chapter output to `./asvs-reports/.resume/V{N}.md`.
       2. **Write the checkpoint** `./asvs-reports/.asvs-resume.json` (format in Step 0): set `current_chapter`, put the still-failing URLs in `pending_urls` and their hosts in `blocked_hosts`, and list finished chapters in `completed_chapters`. Get `created` from `date +"%Y-%m-%dT%H%M"` via Bash.
       3. **Tell the reviewer exactly what to do** and then **stop** — do not proceed further this session: "Checkpoint saved. Allow the host(s) {hosts} in your sandbox's network settings, restart the sandbox, then re-run `/wps:asvs:asvs-review` — I'll resume loading references for V{current_chapter} and continue from here."
     - On `Retry again`: repeat the retry (step 4).
     - On `Continue without`: proceed.
5. If the reviewer chose `Continue without` at any point: proceed to analysis, and for any criterion where a missing reference limited your judgment, say so explicitly in the rationale.

Once references are loaded (or the reviewer chose to continue without some), internalize their content. You will apply this knowledge during the analysis in Step 6 — for example, to recognize insecure patterns specific to a framework, to know what a compliant implementation looks like, or to identify subtle violations that are not obvious from the ASVS criterion text alone.

Do not mention successful reference loading in your output — it is preparation work only. Do briefly note any references the reviewer chose to skip, so the report's readers know which guidance was unavailable.

---

## Step 6 — Analysis

Read the target ASVS chapter file and establish the set of criteria in scope.

**Filtering:**

- Include only criteria with Level ≤ configured `level`
- Skip any criterion whose ID appears in `excluded_criteria` or in the session-level exclusions from Step 4
- Apply any context from Step 4 answers (e.g., if auth is external, mark auth storage criteria as NOT APPLICABLE with a note)

**Work file-by-file, not criterion-by-criterion.** Reading the same source file once per criterion re-sends its whole content into context every time and is the main avoidable input-token cost of a review. Instead:

1. From the in-scope criteria and `projectStructure`, determine which components, folders, and file types this chapter actually touches. When a criterion is only relevant to one component (e.g. a frontend- or backend-only concern), scope it there and note that in the evidence.
2. Locate the relevant code with targeted `Grep` searches — entry points, security-relevant APIs, and the specific patterns for this chapter's topic. Do not read files blindly.
3. Read each relevant file **once**. Prefer a ranged read around the `Grep` hits; do not dump an entire large file when the relevant section suffices.
4. While a file is in context, evaluate **every** in-scope criterion that concerns it. Do not re-open the same file for each criterion.
5. Apply knowledge from the reference documents loaded in Step 5 to recognise secure and insecure patterns.

**For each in-scope criterion, record:**

1. A verdict:
   - `PASS` — the requirement is clearly met by the code
   - `FAIL` — the requirement is clearly violated
   - `NOT APPLICABLE` — the requirement does not apply to this codebase (explain why)
   - `NEEDS MANUAL REVIEW` — cannot be determined statically; human judgment required
2. Evidence: file paths and line numbers where applicable
3. A brief rationale (1–2 sentences), following the output-economy rules — including why a PASS or NOT APPLICABLE holds, so the reviewer can check the assumption behind it
4. For `FAIL` verdicts: if a reference document from Step 5 contains relevant guidance (secure implementation example, recommended pattern, explanation of the attack), cite it — include the original URL from the cached file's `source:` frontmatter field and a one-line summary of what the reader will find there

---

## Step 7 — Output

Produce the findings using `output_format` from the config (default: `table`).

**Write once — do not duplicate the output** (unless the reviewer opted in):

- If `write_report` is `true` and `echo_report_to_session` is `false` (default): the report file is the deliverable. Write the full findings there, and in the session show only a compact recap — the summary line, the FAIL / NEEDS MANUAL REVIEW items (ID + one-line evidence each), and a link to the report file. Do not reprint the full table/checklist in the session.
- If `write_report` is `true` and `echo_report_to_session` is `true`: write the report file **and** print the full findings in the session. This duplicates the output and costs more tokens — only when the reviewer wants results inline.
- If `write_report` is `false`: show the full findings in the session (there is no file to point to).

If `write_report` is `true`, write the report file:

- Directory: `./asvs-reports/` relative to the project being reviewed (create if it does not exist)
- Filename: `{chapterNo}-{chapterTitle}-{iso-datetime}.md` where:
  - `{chapterNo}` is the chapter identifier, e.g. `V9`
  - `{chapterTitle}` is the chapter title in kebab-case; abbreviate to keep it readable (max ~30 chars), e.g. `Self-contained-Tokens` — drop articles, shorten long words if needed
  - `{iso-datetime}` is obtained by running `date +"%Y-%m-%dT%H%M"` via Bash **before** writing the file — never guess or invent the timestamp
  - Full example: `V9-Self-contained-Tokens-2026-06-22T1234.md`
- The report file contains the same content as the session output, preceded by a header with project name (current directory name), chapter, level, and date

### Report formatting rules

**Source file references** — every source file path mentioned anywhere in the report must be a clickable relative link. Because the report lives inside `./asvs-reports/`, all paths must be prefixed with `../` to remain valid from that location. Include the line number in the link text but not in the href:

```
[src/auth/Login.cs:88](../src/auth/Login.cs)
```

**Comprehensive evidence for FAIL and NEEDS MANUAL REVIEW** — list every occurrence found, not just the first one. If the full list fits comfortably in the evidence cell, include it inline. If there are more than 3 occurrences, truncate the cell to the first 2 and add a link to an addendum section:

In the table cell:

```
[src/auth/Login.cs:88](../src/auth/Login.cs), [src/auth/Register.cs:12](../src/auth/Register.cs) — [+4 more occurrences ↓](#addendum-612)
```

Anchor on the table row (add an HTML anchor before the ID):

```html
<a name="finding-612"></a>
```

At the end of the report, add an `## Addendum` section with one subsection per criterion that has an overflow list:

```markdown
## Addendum

### <a name="addendum-612"></a>6.1.2 — All occurrences [↑](#finding-612)

- [src/auth/Login.cs:88](../src/auth/Login.cs) — no length or complexity check
- [src/auth/Register.cs:12](../src/auth/Register.cs) — password accepted without validation
- [src/admin/UserCreate.cs:44](../src/admin/UserCreate.cs) — same issue
- ...
```

The `[↑](#finding-612)` link in the addendum header navigates back to the table row.

### Format: `table`

One row per criterion. Group by section with a section header.

| ID        | Description (short)                  | Level | Verdict | Evidence                                                  |
| :-------- | :----------------------------------- | :---: | :-----: | :-------------------------------------------------------- |
| **1.1.1** | Input decoded before validation      |   1   |  PASS   | `src/input.py:42`                                         |
| **1.1.2** | Output encoding applied contextually |   1   |  FAIL   | `src/templates/user.html:18` — raw variable interpolation |

### Format: `checklist`

Grouped by section, using GitHub-flavoured markdown checkboxes.

```
## V6.1 Authentication Documentation
- [x] **6.1.1** — Authentication guidelines documented (PASS)
- [ ] **6.1.2** — Password policy enforced (FAIL — `auth/password.py:88`)
```

### Format: `findings-only`

Only FAIL and NEEDS MANUAL REVIEW items, ordered by severity (FAIL first). Include a short remediation hint for each FAIL.

```
### FAIL — 6.1.2 Password policy not enforced
**Evidence:** `auth/password.py:88` — no length or complexity check before hashing
**Remediation:** Validate password length (≥12 chars) and reject known-breached passwords before accepting.
**Further reading:** https://pages.nist.gov/800-63-3/sp800-63b.html — NIST SP 800-63B §5.1.1 on memorized secret strength requirements
```

For `table` and `checklist` formats, add a **Further reading** line beneath any FAIL row where a relevant reference exists.

---

## Closing

After output, summarise:

- Total criteria evaluated / passed / failed / not applicable / needs review
- Top 3 risk areas if there are multiple FAILs

**Checkpoint maintenance:**

- In `sequential` and `parallel` modes, after each chapter is finalised, add it to `completed_chapters` in `./asvs-reports/.asvs-resume.json` (create the checkpoint if it does not exist yet). If the chapter's output is not being written to a report file (`write_report` is false), also flush it to `./asvs-reports/.resume/V{N}.md`. This guarantees an unexpected restart never loses completed work.
- When the entire configured run finishes normally, **delete** `./asvs-reports/.asvs-resume.json` and the `./asvs-reports/.resume/` directory — the review is complete and there is nothing to resume.

If execution mode was `parallel` or `sequential` and all configured chapters have been processed, end the session — no further prompt needed.

If execution mode was `single` and more chapters remain in the configured chapter list, use `AskUserQuestion` (single select):

- Header: `Continue`
- Question: `Continue with the next chapter?` (name the next chapter, e.g. `Continue with V8 — Authorization?`)
- Options:
  - `Yes` — proceed immediately with the next chapter (return to Step 3)
  - `No` — end the session

---

## Step numbering reference

0. Resume an interrupted review if a checkpoint exists (skip the interview, continue from the saved point)
1. Load config
   1b. Scan existing reports in `./asvs-reports/` to determine reviewed vs. unreviewed chapters
2. Resolve missing config fields interactively (language, output_format, write_report, level, chapters, projectStructure, context_notes — all saved to config)
3. Select chapter/section for this run (execution mode: single / sequential / parallel / unreviewed-parallel)
4. Interview phase (runtime exclusions only — session-specific, not saved)
   4b. Parallel fan-out via Agent tool _(only in parallel mode — sub-agents read cached references and run Step 6 analysis only; reference loading was done centrally in Step 5)_
5. Load and cache reference documents _(orchestrator only; handles blocked-network access interactively and can checkpoint for a sandbox restart)_
6. Analysis _(sub-agents in parallel mode; the orchestrator otherwise)_
7. Output (+ optional report file); on normal completion, delete the resume checkpoint
