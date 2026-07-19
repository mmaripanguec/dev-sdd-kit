# Demo walkthrough — a customer assistant (Google ADK + Gemini), the factory way

This is the end-to-end session shown in the README's animated demo: starting
from **nothing**, you instantiate the factory, specify a digital customer
assistant (an [ADK](https://google.github.io/adk-docs/) agent using Gemini),
pass the human gates, and build it with strict TDD. The assistant itself is
deliberately simple — the point is the *process* around it: every decision
that matters stops at a human.

The example spec produced by this flow ships in this repo:
[`specs/2026-07-asistente-clientes-adk.md`](../specs/2026-07-asistente-clientes-adk.md)
(Spanish — the factory's working language; structure is self-explanatory).

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
./scripts/init-sistema.sh demo         # clean instance: registry, skills, rules
claude                                 # always launch from the workspace root
```

## 2 · Specify — the factory asks before it assumes

```text
/spec-create customer-assistant "ADK agent on Gemini that answers customer questions"
```

The F0 triage classifies this as a **new application** (no repo exists yet →
task T0 will create it). Ambiguity triggers `/clarificar` — max 5 targeted
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
                    /consistencia (cross-artifact)   👤 you: "aprobado"
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

## 5 · Run it and see the human-in-the-loop

```bash
adk run customer_assistant        # or `adk web` for the browser UI
```

```text
› client:    "I think there's a charge I didn't make on my card"
⚠ sensitive  (possible fraud) → escalated, draft reply queued
👤 human     reviews the draft → approves ✔
› assistant  (gemini-2.5-flash): "I've alerted our team — your card is
             protected. Here's what happens next…"
```

An FAQ question ("what are your opening hours?") is answered instantly with
the FAQ entry cited; anything not in the curated FAQ gets an honest *"I
don't have that information — let me connect you"* — the same **"no source →
no answer"** principle the factory applies to its own metrics.

## 6 · Certify and close

```text
/convergir specs/2026-07-customer-assistant.md    # every criterion vs real code
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
