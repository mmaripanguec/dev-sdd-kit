# Demo walkthrough — a customer assistant (Google ADK + Gemini), the factory way

This is the end-to-end session shown in the README's animated demo: starting
from **nothing**, you instantiate the factory, specify a digital customer
assistant (an [ADK](https://google.github.io/adk-docs/) agent using Gemini),
pass the human gates, and build it with strict TDD. The assistant itself is
deliberately simple — the point is the *process* around it: every decision
that matters stops at a human.

The example spec produced by this flow ships in this repo:
[`specs/2026-07-customer-assistant-adk.md`](../specs/2026-07-customer-assistant-adk.md)
(English — the demo chose `--lang en` at instantiation).

## 0 · Prerequisites

```bash
git --version          # git 2.x
python3 --version      # 3.10+
claude --version       # Claude Code CLI — https://claude.com/claude-code
```

For the assistant itself (phase F6, after the gates):

```bash
pip install google-adk                 # Google Agent Development Kit
export GOOGLE_API_KEY=<your-key>       # from Google AI Studio — NEVER commit it
```

## 1 · Environment from scratch (~1 minute)

```bash
git clone <template-url> demo && cd demo
./scripts/init-system.sh assistant-demo
# ? Working language for specs and interactions? [en/es] (default en): en
#   → saved as `system.lang: en` and kept consistent from here on.
#   Command names are ALWAYS English, whatever language you pick.
claude                                 # always launch from the workspace root
```

## 2 · Specify — the factory asks before it assumes

```text
/spec-create customer-assistant "ADK agent on Gemini that answers customer questions"
```

The F0 triage classifies this as a **new application** (no repo exists yet →
task T0 will create it). Ambiguity triggers `/clarify` — max 5 targeted
questions, answers recorded in the spec:

```text
? 1/2  Knowledge source:   [A] curated FAQ file   [B] live website      → A
? 2/2  Sensitive topics:   [A] auto-answer        [B] escalate to HUMAN → B
```

The result is a 12-section spec: prioritized stories with Gherkin criteria,
measurable success criteria (e.g. *"100% of sensitive topics escalate to a
human — zero automatic answers, auditable by log"*), edge cases including
prompt injection, and a task plan where the escalation control lives **in
code, not in the prompt** — instructions to an LLM are not a control
mechanism.

## 3 · The human gates — where YOU decide

```text
⏸ GATE PO/TL        stories & priorities            👤 you: "aprobado"
⏸ GATE DoR          /spec-review (13-point check)
                    /consistency (cross-artifact)   👤 you: "aprobado"
⏸ GATE Architecture contracts · STRIDE threat model  👤 you: "aprobado"
```

Every approval is recorded in the spec — who, when, on which commit. Agents
*cannot* approve their own work: the gates are enforced by tool permissions,
not by prompt text.

## 4 · Build — strict TDD

```text
/implement-task specs/2026-07-customer-assistant.md T0   # creates the app repo
/implement-task specs/2026-07-customer-assistant.md T1   # RED: failing tests first
```

T1 commits the **failing tests for the critical rule first** — "a sensitive
topic can never be auto-answered" — then implements until green. Editing a
test to make it pass is forbidden by the factory rules.

## 5 · Run it — real recorded session

This is the actual output of the built assistant (offline mode, no API key):

```text
$ python3 -m assistant.cli "What are your opening hours?"
customer  › What are your opening hours?
assistant › We are open Monday to Friday from 9:00 to 18:00 and Saturdays
            from 10:00 to 14:00… (official source: FAQ)
            [faq.md#hours · offline mode]

$ python3 -m assistant.cli "There's a charge on my card I don't recognize"
assistant › Your case needs a human agent and I have already escalated it
            with priority…
            [SENSITIVE → case #1 queued; draft awaiting human approval]
```

**The human validation moment** — nothing is sent until a person decides:

```text
$ python3 -m assistant.approve
#1 [2026-07-20T00:18:36Z] There's a charge on my card I don't recognize
   draft: We're sorry about the trouble. We have taken preventive action…

$ python3 -m assistant.approve 1 --text "We have preventively blocked your card…"
case #1 APPROVED by mmaripanguec (2026-07-20T00:18:44Z)
reply sent › We have preventively blocked your card…
```

Who approved, when, and what they edited is recorded in
`state/approved.json`. And anything outside the curated FAQ gets an honest
*"I don't have that information… I'd rather not make up an answer"* — the
same **"no source → no answer"** principle the factory applies to its own
metrics.

## 6 · Where everything lives · configuration

```
repos/customer-assistant/
├── assistant/            # core.py (FAQ + sensitivity in CODE) · escalation.py
│                         # gemini_adk.py · cli.py · approve.py
├── tests/test_rules.py   # the 5 RED-first tests (BR-A1 / BR-A2)
├── faq.md                # curated knowledge — the ONLY answer source
├── state/                # pending.json · approved.json (gitignored)
└── .env.example          # copy to .env and fill in:
```

```bash
cp .env.example .env && chmod 600 .env
# GOOGLE_API_KEY=<from https://aistudio.google.com/apikey>  — NEVER commit it
# GEMINI_MODEL=gemini-2.5-flash
```

Without a key the assistant runs in **offline mode** (official FAQ answers,
verbatim). With a key, Gemini rewrites the phrasing — but only ever over the
curated FAQ content: the source rule is enforced in code either way.

## 7 · Certify and close

```text
/converge specs/2026-07-customer-assistant.md    # every criterion vs real code
⏸ GATE QA/PR                                      👤 you: "aprobado" → shipped
```

Operations (F9) then feeds back: session logs update the success criteria,
incidents become blameless postmortems, and DORA metrics derive from the
repo's own git history — closing the loop for the next feature.

---

**Why this example matters:** an AI assistant answering customers is exactly
the kind of software that should *not* be vibe-coded. The factory makes the
safety property (human approval on sensitive topics) a spec-level contract,
tested in RED before any implementation exists, and verified again at
certification — the same discipline the factory applies to itself.
