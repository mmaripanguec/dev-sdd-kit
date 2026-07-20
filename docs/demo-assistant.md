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

## 5 · Run it — real recorded session

This is the actual output of the built assistant (offline mode, no API key):

```text
$ python3 -m asistente.cli "¿Cuál es el horario de atención?"
cliente   › ¿Cuál es el horario de atención?
asistente › Atendemos de lunes a viernes de 9:00 a 18:00 y sábados de
            10:00 a 14:00… (fuente oficial: FAQ)
            [faq.md#horario · modo offline]

$ python3 -m asistente.cli "Hay un cargo que no reconozco en mi tarjeta"
asistente › Tu caso requiere atención de un ejecutivo humano y ya lo
            derivé con prioridad…
            [SENSIBLE → caso #1 encolado; borrador listo para aprobación]
```

**The human validation moment** — nothing is sent until a person decides:

```text
$ python3 -m asistente.aprobar
#1 [2026-07-20T00:06:08Z] Hay un cargo que no reconozco en mi tarjeta
   borrador: Lamento el inconveniente. Tomamos medidas preventivas…

$ python3 -m asistente.aprobar 1 --texto "Bloqueamos preventivamente tu tarjeta…"
caso #1 APROBADO por mmaripanguec (2026-07-20T00:06:15Z)
respuesta enviada › Bloqueamos preventivamente tu tarjeta…
```

Who approved, when, and what they edited is recorded in
`estado/aprobados.json`. And anything outside the curated FAQ gets an honest
*"No tengo esa información… prefiero no inventar"* — the same **"no source →
no answer"** principle the factory applies to its own metrics.

## 6 · Where everything lives · configuration

```
repos/asistente-clientes/
├── asistente/            # nucleo.py (FAQ + sensitivity in CODE) · cola.py
│                         # gemini_adk.py · cli.py · aprobar.py
├── tests/test_reglas.py  # the 5 RED-first tests (RN-A1 / RN-A2)
├── faq.md                # curated knowledge — the ONLY answer source
├── estado/               # pendientes.json · aprobados.json (gitignored)
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
