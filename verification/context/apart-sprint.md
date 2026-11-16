# Context: Apart Research "AI x Epistemics" sprint (Nov 13–15, 2026)

Source: https://apartresearch.com/sprints/ai-x-epistemics-research-sprint-2026-11-13-to-2026-11-15#guidelines (read 2026-11-15; paraphrased, short quotes only).

The upstream pilot was produced on the final day of this sprint and is most likely a submission to it.

## Key rules relevant to this verification

- **Deadline:** Sun Nov 15, 2026, 11:59 PM AoE (UTC-12) = **Mon Nov 16, 11:59 UTC**. Resubmitting with the same title before the deadline replaces the earlier submission.
- **Required:** a PDF built from the official template, at most 8 pages excluding references and appendices, a 150–250 word abstract, and a mandatory **"Limitations and Dual-Use / Ethical Considerations"** appendix.
- **Recommended structure:** Introduction, Related Work, Methodology ("enough detail to replicate"), Results ("report variance and baselines"), Discussion, Limitations, References.
- **AI use:** "Use AI tools however they help you." The team is responsible for all content, and **"made-up results or references can disqualify a project."** Pre-sprint work must be disclosed.
- **Judging:** 1–5 on each of three dimensions, with no published weights:
  1. Impact Potential & Innovation (including whether the work is new or replicates recent work)
  2. Execution Quality ("How sound are methodology, implementation, and findings?")
  3. Presentation & Clarity
- **Tracks:** 1 Model Epistemics & Decision-Making Evals · **2 Trust Infrastructure** (source reliability, provenance tools, citation verification) · 3 Epistemic Products · **4 Open Track** (meta-questions).
- Template: https://docs.google.com/document/d/17b3JWki-ZkaqdmqGI5d0gof-HwlGuWU9Mc1_klNZXKs/copy?usp=sharing

## How the findings map onto the rubric

| Rubric item | Pilot status | Related findings |
|---|---|---|
| "made-up results or references" | Arm 7's 0/20 comes from the code rejecting poison by ID, not from a measurement. The PoisonedRAG arXiv ID points to an unrelated paper. | F1, C1 |
| "report variance and baselines" | No variance: one poison generation and n=20 | F8 |
| Limitations appendix | Present in report §6 but incomplete. It omits F1, P2 and P3. | F1, P2, P3 |
| Execution quality | Arms added post hoc, mixed code versions | P2, P3 |
