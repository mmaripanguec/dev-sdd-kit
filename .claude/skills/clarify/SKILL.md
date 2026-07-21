---
name: clarify
description: Resolves the ambiguities of a requirement or spec with structured questions (max. 5) and records the answers in the spec's Clarifications section. Use between the F0 triage and F1, when asked to "clarify the requirement", or when a spec has [NEEDS CLARIFICATION] markers.
argument-hint: "<spec-path | requirement description>"
allowed-tools: Read Glob Grep Edit
---

Clarify: $ARGUMENTS

## Step 1 — Ambiguity scan
Read the requirement (or the spec and its `[NEEDS CLARIFICATION]` markers)
together with the factory context (repos.yaml, current context packs, as-is,
knowledge/business-rules.md). Assess coverage per category — Clear /
Partial / Absent:
scope and out of scope · actors and permissions · main and alternative
flows · data and entities · business rules · external dependencies ·
NFRs (volume, latency, availability) · security/privacy/
regulatory · edge cases · measurable success criteria.

## Step 2 — Questions (maximum 5)
Only ask what meets ALL THREE: (a) Partial/Absent category,
(b) the answer changes scope, design or certification, (c) there is no
reasonable default in the loaded context. Priority: scope > security/privacy >
UX > technical detail. Format per question: concrete statement + options
table (A, B, C… and "Other") with each option's implication in one line.
Present the questions one at a time or as a block, whichever the user
prefers; everything else is NOT asked: the default is assumed and noted as
an assumption.

## Step 3 — Record
With the answers:
1. Add/update in the spec the section `## Clarifications` →
   `### Session <today's date>` with format `- Q: <question> → A: <answer>
   (decides: <who>)`.
2. Integrate each answer into the corresponding section of the spec
   (stories, analysis, out of scope…) and remove its
   `[NEEDS CLARIFICATION]` marker.
3. Ambiguities detected but not asked (they exceeded the maximum or had a
   default): into the Assumptions block of the Analysis section, or as a
   marker if they block (maximum 3 live markers in the spec).

If no spec exists yet (a requirement prior to /spec-create is being
clarified), deliver the summary of decisions so /spec-create incorporates
it from F1. Do not modify anything outside the indicated spec.
