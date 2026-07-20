# Spec: Customer digital assistant (ADK agent + Gemini)

| Field | Value |
|---|---|
| Status | draft — EXAMPLE SPEC for the "new application" flow (factory demo) |
| Requirement type | new application (F0 triage: no repo exists; T0 creates it) |
| Context loaded | none prior (new app); Google ADK + Gemini API as proposed stack |
| Business domain | customer service |
| Working language | English (chosen at `init-system.sh` — `system.lang: en`) |
| Author / Date | Claude + Marcos Maripangue / 2026-07-19 |
| PO/TL gate | pending |
| DoR gate | pending |
| Architecture gate | pending |

> This spec is the EXAMPLE that accompanies the README demo: it shows how
> the factory specifies a brand-new application end to end. It gets
> implemented only when a human approves its gates — like any other.

## 1. Problem
Customers ask the same questions through saturated channels (hours,
requirements, request status) and wait minutes for answers that already live
in the FAQ. The support team burns its time on the repetitive cases and
arrives late to the delicate ones — where human judgment actually matters.

## 2. Objective
A conversational digital assistant — an agent built with Google ADK and a
Gemini model — answers frequent questions instantly from a controlled
knowledge base, and escalates everything sensitive to a human with a draft
reply ready for approval.

## 3. Success criteria
- SC-01 ≥ 70% of FAQ questions resolved with no human intervention
  (measured on the session log over the first month).
- SC-02 100% of topics flagged sensitive escalate to a human; zero
  automatic replies in that category (auditable by log).
- SC-03 First-response time < 5 seconds p95.

## 4. Out of scope
- Executing transactions (payments, data changes): the assistant informs
  and escalates; it never operates accounts.
- Voice and WhatsApp channels (v2; this version is web/terminal chat).
- Model training/fine-tuning: Gemini is used via API with context.

## 5. Clarifications
### Session 2026-07-19
- Q: Working language? → A: English (`init-system.sh` asked at
  instantiation; recorded as `system.lang: en` — kept consistent from here
  on) (decides: Marcos).
- Q: Knowledge source? → A: a curated FAQ file versioned in the repo
  (`faq.md`), maintained by the team — no scraping, no live sources
  (decides: Marcos as the example's PO).
- Q: Sensitive topics — answer or escalate? → A: ALWAYS escalate to a
  human with a proposed draft reply; the human approves, edits or discards
  it (decides: Marcos — it is also the exact behavior the demo evidences).

## 6. User stories (F1 · INVEST)
### S1 [P1] — Answer frequent questions
As a customer, I want to ask in natural language and get the official
answer instantly, so I don't wait for an agent for something already in the FAQ.
**Acceptance criteria (Gherkin):**
- AC1.1 Given the curated FAQ, when I ask something it covers, then the
  agent answers using ONLY that content as source (Gemini for understanding
  and phrasing) and cites the FAQ entry used.
- AC1.2 Given something NOT covered by the FAQ, when I ask, then the agent
  says so explicitly and offers to escalate — it never makes things up
  ("no source ⇒ no answer", the same principle the factory applies to its
  own metrics).
- AC1.3 Given any reply, when it is emitted, then it lands in the session
  log (question, answer, source, latency).

### S2 [P1] — Escalation with human approval
As the support lead, I want sensitive topics (claims, fraud, personal data,
cancellations) to reach a human with a draft ready, so we respond fast
without surrendering judgment to the machine.
**Acceptance criteria (Gherkin):**
- AC2.1 Given a topic classified as sensitive, when the customer asks it,
  then the agent says a human will take over and queues the case with a
  proposed draft reply.
- AC2.2 Given the queued case, when the human approves/edits the draft,
  then that reply is sent and the decision is recorded (who, when, what
  changed).
- AC2.3 Given a sensitive case, when there is NO human approval, then NO
  automatic reply is ever sent (verified by test).

### S3 [P2] — Session with context
As a customer, I want the assistant to remember the ongoing conversation,
so I don't repeat my details on every question.
**Acceptance criteria (Gherkin):**
- AC3.1 Given an ongoing dialog, when I ask a follow-up, then the agent
  resolves references ("and how long does that take") using ADK session state.

## 7. Estimation (F2)
| Story | Points | Complexity | Assumptions |
|---|---|---|---|
| S1 agent + FAQ + citations | 5 | medium | ADK Agent + FAQ lookup tool |
| S2 human escalation | 5 | medium | simple queue + approval CLI |
| S3 session context | 2 | low | native ADK session state |
WSJF priority: S1 → S2 → S3 (S1+S2 are the MVP: value + human control).

## 8. Analysis (F4)
**Business rules:** BR-A1 the agent only asserts what the curated FAQ
contains (no source ⇒ escalate); BR-A2 sensitive topic ⇒ MANDATORY human
approval, no exceptions and no agent override; BR-A3 the session log keeps
no personal data beyond the conversation itself.
**Dependencies:** Google ADK (`google-adk` package, Python ≥3.10) · Gemini
API (Google AI Studio key via `GOOGLE_API_KEY`; never in the repo — the
factory's secrets rule applies).
**Edge cases:** question ambiguous between FAQ and sensitive (sensitive
wins) · Gemini API down or rate-limited (honest message + escalation, no
infinite retries) · empty FAQ (everything escalates) · language other than
the FAQ's (answer in the customer's language using FAQ content) · prompt
injection ("ignore your rules") — BR-A1/A2 are enforced IN CODE
(classifier + queue), not in the prompt.
**Assumptions:** sensitivity classification via topic list + Gemini as a
second check (validated at the Architecture gate) · English as the FAQ's
primary language.
**Regulatory:** personal data in conversations — minimal retention, no
training use (API terms honored).

## 9. Design (F5)
**Stack:** Python + Google ADK (`Agent` with `model="gemini-2.5-flash"`,
instructions + tools) · `search_faq` tool (lookup over faq.md) ·
`escalate_to_human` tool (queues case with draft) · CLI / `adk web` as the
conversation surface · approval queue with an `approve` command for the human.
**Contracts:** internal (typed agent tools); no public API in v1.
**ADR-01 (proposed):** sensitivity control lives OUTSIDE the prompt
(code classifier + approval queue) because LLM instructions are not a
control mechanism — the factory's own permissions-over-prompts principle.
**Threat model (STRIDE):** applies (personal data + LLM exposed to hostile
input): approver identity spoofing → local auth; prompt injection → rules
in code (BR-A2); information disclosure → the FAQ is the only source; abuse
DoS → per-session rate limit.
**NFRs:** p95 < 5 s (SC-03); per-query cost monitored; 100% coverage on
the escalation path (it is the critical route).

## 10. Task plan (F6)
- [ ] T0 [workspace] create `customer-assistant` repo + /repo-add + ADK
      scaffolding (venv, google-adk, agent layout) + initial as-is and pack
- [ ] T1 [customer-assistant] RED tests for BR-A1/BR-A2 first (FAQ as only
      source; sensitive never auto-answers) — the critical route first
- [ ] T2 [customer-assistant] ADK agent with `search_faq` + citations
      (AC1.1–AC1.3) until green
- [ ] T3 [customer-assistant] sensitivity classifier + queue + human
      approval command (AC2.1–AC2.3) until green
- [ ] T4 [customer-assistant] [P] session state (AC3.1) + logging
- [ ] T5 [workspace] [P] initial faq.md curated by the PO

## 11. Certification (F7)
/converge with no pending gaps + quality agent verdict (includes SC-01..03
from §3) + QA/PR gate: __

## 12. Traceability
Origin: requested by Marcos (2026-07-19) as the demonstrative example of
the factory's "new application" flow; accompanies the README demo
(docs/assets/demo.svg and docs/demo-assistant.md). Status: draft until its
gates are approved — the demo shows the path, it does not skip it.
